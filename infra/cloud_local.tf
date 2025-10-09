data "local_file" "schema" {
  filename = "${path.module}/db/schema.sql"
}

locals {
  # ✅ remove newlines so it’s one clean line for PowerShell
  schema_b64 = replace(base64encode(data.local_file.schema.content), "/\\r?\\n/", "")
}

resource "null_resource" "apply_schema" {
  depends_on = [aws_db_instance.mysql]

  triggers = {
    schema_sha  = data.local_file.schema.content_sha256
    db_endpoint = aws_db_instance.mysql.address
  }

  provisioner "local-exec" {
    # ✅ call PowerShell by absolute path (avoids PATH issues)
    interpreter = [
      "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
      "-NoProfile","-NonInteractive","-ExecutionPolicy","Bypass","-Command"
    ]

    command = <<-POW
      $ErrorActionPreference = 'Stop'

      # -------- Inputs from Terraform --------
      $Region   = "${var.region}"
      $DbHost   = "${aws_db_instance.mysql.address}"
      $DbName   = "StudentDb"
      $DbUser   = "adminuser"
      $AppSSM   = "/one-project/mysql/app"
      $Instance = "${aws_instance.win.id}"

      # ✅ simple single-quoted assignment (no here-string!)
      $SchemaB64 = '${local.schema_b64}'

      # -------- Build the script that runs ON THE EC2 --------
      $Ps = @"
      \$ErrorActionPreference = 'Stop'

      \$Region = '$Region'
      \$DbHost = '$DbHost'
      \$DbName = '$DbName'
      \$DbUser = '$DbUser'

      # ✅ inject the value safely (quoted)
      \$SchemaB64 = '$SchemaB64'

      # Paths on the EC2 instance
      \$TmpDir     = 'C:\\temp\\schema'
      \$SchemaPath = Join-Path \$TmpDir 'schema.sql'
      New-Item -ItemType Directory -Force -Path \$TmpDir | Out-Null

      # Retrieve app password from SSM Parameter Store (SecureString)
      \$appJson = aws ssm get-parameter --name "$AppSSM" --with-decryption --region \$Region | ConvertFrom-Json
      \$AppPwd  = \$appJson.Parameter.Value

      # Ensure MySQL client exists
      if (-not (Get-Command mysql.exe -ErrorAction SilentlyContinue)) {
        if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
          throw 'Chocolatey not found; cannot auto-install MySQL client. Preinstall it in the AMI or install Chocolatey.'
        }
        choco install mysql --no-progress -y | Out-Null
        \$clientBin = 'C:\\Program Files\\MySQL\\MySQL Server 8.0\\bin'
        if (Test-Path \$clientBin) { \$env:PATH = "\$clientBin;\$env:PATH" }
      }

      # Decode schema and apply
      [IO.File]::WriteAllBytes(\$SchemaPath, [Convert]::FromBase64String(\$SchemaB64))
      if (-not (Test-Path \$SchemaPath)) { throw "Failed to materialize schema at: \$SchemaPath" }

      Write-Host "Applying schema from: \$SchemaPath to \$DbHost / \$DbName as \$DbUser"
      \$cmd = "mysql.exe -h \$DbHost -P 3306 -u \$DbUser -p\$AppPwd \$DbName < `"\$SchemaPath`""
      cmd.exe /c \$cmd

      Write-Host 'Schema applied successfully.'
"@

      # -------- Invoke on the instance via SSM --------
      $CmdId = (aws ssm send-command `
        --instance-ids $Instance `
        --document-name "AWS-RunPowerShellScript" `
        --parameters commands="$Ps" `
        --region $Region `
        --query "Command.CommandId" `
        --output text)

      # -------- Wait for completion --------
      do {
        Start-Sleep -Seconds 4
        $inv = aws ssm list-command-invocations --command-id $CmdId --details --region $Region | ConvertFrom-Json
        $state = $inv.CommandInvocations[0].Status
        Write-Host "SSM status: $state"
      } while ($state -in @('Pending','InProgress','Delayed'))

      if ($state -ne 'Success') {
        $detail = ($inv.CommandInvocations[0].CommandPlugins | ConvertTo-Json -Depth 8)
        Write-Host $detail
        throw "Schema apply failed with status: $state"
      }

      Write-Host "Schema apply finished successfully."
    POW
  }
}

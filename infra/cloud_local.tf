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

  provisioner "remote-exec" {
    inline = [
      "$ErrorActionPreference = 'Stop'",
      "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12",

      # Vars from TF
      "$Region    = '${var.region}'",
      "$DbHost    = '${aws_db_instance.mysql.address}'",
      "$DbName    = '${var.db_name}'",
      "$DbUser    = '${var.db_admin_username}'", # using admin user to initialize schema
      "$AppParam  = '${var.app_pwd_param_name}'",
      "$SchemaB64 = '${local.schema_b64}'",

      # Ensure temp dir, materialize schema
      "New-Item -ItemType Directory -Force -Path 'C:\\temp\\schema' | Out-Null",
      "$schemaPath = 'C:\\temp\\schema\\schema.sql'",
      "[IO.File]::WriteAllBytes($schemaPath, [Convert]::FromBase64String($SchemaB64))",

      # Install AWS CLI if missing (for SSM get-parameter)
      "if (-not (Get-Command aws.exe -ErrorAction SilentlyContinue)) {",
      "  $msi = 'C:\\temp\\AWSCLIV2.msi'",
      "  (New-Object Net.WebClient).DownloadFile('https://awscli.amazonaws.com/AWSCLIV2.msi', $msi)",
      "  Start-Process msiexec.exe -ArgumentList @('/i',$msi,'/qn') -Wait -NoNewWindow",
      "  $env:Path = 'C:\\Program Files\\Amazon\\AWSCLIV2;' + $env:Path",
      "}",

      # Ensure MySQL client (via Chocolatey)
      "if (-not (Get-Command mysql.exe -ErrorAction SilentlyContinue)) {",
      "  if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {",
      "    Set-ExecutionPolicy Bypass -Scope Process -Force;",
      "    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;",
      "    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'));",
      "  }",
      "  choco install mysql --no-progress -y | Out-Null",
      "  $clientBin = 'C:\\Program Files\\MySQL\\MySQL Server 8.0\\bin';",
      "  if (Test-Path $clientBin) { $env:Path = \"$clientBin;\" + $env:Path }",
      "}",

      # Get APP password from SSM (requires IAM role)
      "$appJson = aws ssm get-parameter --name $AppParam --with-decryption --region $Region | ConvertFrom-Json",
      "$AppPwd  = $appJson.Parameter.Value",

      # Apply schema
      "Write-Host \"Applying schema to $DbHost / $DbName as $DbUser\"",
      "cmd.exe /c \"mysql.exe -h $DbHost -P 3306 -u $DbUser -p$AppPwd $DbName < $schemaPath\"",
      "Write-Host 'Schema applied successfully.'"
    ]

    # WinRM connection to the Windows EC2
    connection {
      type     = "winrm"
      host     = aws_instance.win.public_ip
      user     = "root"
      password = rsadecrypt(aws_instance.win.password_data, file(var.private_key_path))
      https    = false
      insecure = true
      timeout  = "15m"
    }
  }
}
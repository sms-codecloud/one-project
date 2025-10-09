<powershell>
    # Optional: install IIS quickly
    Install-WindowsFeature Web-Server

    # Install AWS CLI v2 if missing (many Windows AMIs have it preinstalled)
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
      $zip = "$env:TEMP\\awscliv2.zip"
      Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "$env:TEMP\\AWSCLIV2.msi"
      Start-Process msiexec.exe -ArgumentList "/i `"$env:TEMP\\AWSCLIV2.msi`" /qn" -Wait
    }

    # Fetch SecureString parameter and set system-wide env var for .NET
    $param = aws ssm get-parameter --name "${var.ssm_parameter_path}" --with-decryption --query "Parameter.Value" --output text
    [Environment]::SetEnvironmentVariable("ASPNETCORE_ConnectionStrings__Default", $param, "Machine")

    # Optional: write a .env file for debugging
    "ASPNETCORE_ConnectionStrings__Default=$param" | Out-File -Encoding UTF8 -Force "C:\deploy\api\.env"

    # Recycle IIS to pick up the new env var
    Import-Module WebAdministration
    Restart-WebAppPool -Name "one-project-app" -ErrorAction SilentlyContinue
    iisreset
</powershell>
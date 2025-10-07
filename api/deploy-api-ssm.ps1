<#
.SYNOPSIS
Deploys the .NET API (StudentApi.dll) to Windows EC2 using AWS SSM.
Assumes EC2 already has IIS + Hosting Bundle + MySQL 9.4 from infra pipeline.

.PARAMETER InstanceId
AWS EC2 instance ID

.PARAMETER Region
AWS region (default ap-south-1)

.PARAMETER Bucket
S3 bucket containing the published ZIP

.PARAMETER Key
S3 key (object path) for the artifact zip

.PARAMETER MySQLAppPassword
Password used by 'student_user' MySQL user

.NOTES
Run on Jenkins Windows agent with AWS CLI v2 installed and AWS credentials bound.
#>

param(
    [Parameter(Mandatory = $true)] [string]$InstanceId,
    [Parameter(Mandatory = $false)] [string]$Region = "ap-south-1",
    [Parameter(Mandatory = $true)] [string]$Bucket,
    [Parameter(Mandatory = $true)] [string]$Key,
    [Parameter(Mandatory = $true)] [string]$MySQLAppPassword
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Building SSM deploy payload for EC2: $InstanceId ==="

# --- Build connection string for app runtime ---
$conn = "Server=127.0.0.1;Port=3306;Database=StudentDb;User=student_user;Password=$MySQLAppPassword;TreatTinyAsBoolean=false;SslMode=None"

# --- Remote PowerShell that will run on the EC2 instance ---
$remotePS = @'
$ErrorActionPreference = "Stop"
Import-Module WebAdministration
aws --version | Out-Null

# --- Vars injected from Jenkins/SSM ---
$bucket = "{{BUCKET}}"
$key    = "{{KEY}}"
$zip    = "C:\deploy\incoming\api.zip"
$temp   = "C:\deploy\incoming\api_unzip"
$apiDir = "C:\deploy\api"
$webDir = "C:\deploy\web"

Write-Host "Starting API deployment on EC2..."

# --- 1) Ensure folders exist ---
New-Item -ItemType Directory -Force -Path "C:\deploy","C:\deploy\incoming",$apiDir,$webDir | Out-Null

# --- 2) Set ASP.NET Core connection string env (IIS site env variable) ---
$overrideConn = "{{CONN}}"
if ($overrideConn -and $overrideConn.Length -gt 0) {
  Write-Host "Setting ConnectionStrings__Default in IIS env..."
  & $env:SystemRoot\System32\inetsrv\appcmd.exe set config "Default Web Site/api" `
    /section:system.webServer/aspNetCore /+"environmentVariables.[name='ConnectionStrings__Default',value='$overrideConn']" /commit:apphost 2>$null
  & $env:SystemRoot\System32\inetsrv\appcmd.exe set config "Default Web Site/api" `
    /section:system.webServer/aspNetCore /"environmentVariables.[name='ConnectionStrings__Default'].value:$overrideConn" /commit:apphost 2>$null
}

# --- 3) Download artifact from S3 ---
if (Test-Path $zip) { Remove-Item $zip -Force }
aws s3 cp "s3://$bucket/$key" $zip --only-show-errors
Write-Host "Downloaded artifact: s3://$bucket/$key"

# --- 4) Unzip and validate ---
if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
New-Item -ItemType Directory -Path $temp | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $temp)
if (!(Test-Path (Join-Path $temp 'StudentApi.dll'))) { throw "StudentApi.dll not found in artifact." }

# --- 5) Atomic deploy: replace api dir ---
if (Test-Path $apiDir) { Remove-Item "$apiDir\*" -Recurse -Force -ErrorAction SilentlyContinue }
Copy-Item "$temp\*" $apiDir -Recurse -Force
Write-Host "Copied new API files to $apiDir"

# --- 6) Ensure IIS site + app exist ---
if (-not (Test-Path IIS:\Sites\one-project)) {
  Write-Host "Creating IIS site: one-project"
  New-Item IIS:\Sites\one-project -bindings @{protocol='http';bindingInformation='*:80:'} -physicalPath $webDir | Out-Null
}
if (-not (Test-Path 'IIS:\Sites\one-project\api')) {
  Write-Host "Creating IIS application: /api"
  New-WebApplication -Site 'one-project' -Name 'api' -PhysicalPath $apiDir -ApplicationPool 'DefaultAppPool' | Out-Null
} else {
  Set-ItemProperty 'IIS:\Sites\one-project\api' -Name physicalPath -Value $apiDir
  Write-Host "Updated IIS application path for /api"
}

# --- 7) Restart IIS components ---
Stop-WebAppPool -Name "DefaultAppPool" -ErrorAction SilentlyContinue
Start-WebAppPool -Name "DefaultAppPool"
Start-Website -Name "one-project"

# --- 8) Optional health check ---
try {
  $resp = Invoke-WebRequest -Uri "http://localhost/api/health" -UseBasicParsing -TimeoutSec 10
  Write-Host "Health check OK: $($resp.StatusCode)"
} catch {
  Write-Warning "Health endpoint not reachable; continuing."
}

Write-Host "✅ Deployment complete on EC2."
'@

# --- Inject dynamic vars into the remote script ---
$remotePS = $remotePS.Replace("{{BUCKET}}", $Bucket).Replace("{{KEY}}", $Key).Replace("{{CONN}}", $conn)

# --- Convert to JSON for AWS CLI ---
$paramsJson = @{ commands = @($remotePS) } | ConvertTo-Json -Compress

Write-Host "Invoking SSM send-command..."

# --- Run the AWS SSM command safely ---
$commandId = aws ssm send-command `
    --instance-ids $InstanceId `
    --document-name "AWS-RunPowerShellScript" `
    --parameters $paramsJson `
    --region $Region `
    --query "Command.CommandId" `
    --output text `
    --cli-binary-format raw-in-base64-out

if (-not $commandId) {
    throw "❌ Failed to dispatch SSM command."
}

Write-Host "SSM CommandId: $commandId"
Start-Sleep -Seconds 10

aws ssm get-command-invocation `
    --command-id $commandId `
    --instance-id $InstanceId `
    --region $Region `
    --query 'Status,StandardOutputContent,StandardErrorContent' `
    --output text

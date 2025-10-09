<powershell>
# ================== Prep ==================
$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dl = "C:\_bootstrap\dl"
$new = New-Item -Force -ItemType Directory -Path $dl
$rootApp = "C:\inetpub\wwwroot\app"
$rootApi = "C:\inetpub\wwwroot\api"
New-Item -Force -ItemType Directory -Path $rootApp,$rootApi | Out-Null

# ================== Chocolatey (for convenience) ==================
if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
  Set-ExecutionPolicy Bypass -Scope Process -Force
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
$env:PATH = "$env:PATH;C:\ProgramData\chocolatey\bin"

# ================== IIS & core features ==================
Import-Module ServerManager
Add-WindowsFeature Web-Server, Web-WebSockets, Web-Static-Content, Web-Http-Errors, Web-Http-Logging, Web-Request-Monitor, Web-Mgmt-Tools | Out-Null
try { choco install iis-urlrewrite --no-progress -y | Out-Null } catch { Write-Warning "URL Rewrite install skipped: $($_.Exception.Message)" }

# ================== .NET 8 ASP.NET Core Hosting Bundle (ANCM v2) ==================
$hostingInstalled = $false
try {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install --id Microsoft.DotNet.HostingBundle.8 -e --silent --accept-package-agreements --accept-source-agreements
    $hostingInstalled = $true
  }
} catch { Write-Warning "winget HostingBundle install failed: $($_.Exception.Message)" }

if (-not $hostingInstalled) {
  try { choco install dotnet-8.0-windowshosting --no-progress -y | Out-Null; $hostingInstalled = $true }
  catch { Write-Warning "Chocolatey HostingBundle install failed." }
}

if (-not $hostingInstalled) {
  try {
    $hostingUrl = "https://dotnet.microsoft.com/permalink/dotnetcore-8-windowshosting"
    $hostingMsi = Join-Path $dl "dotnet-hosting-bundle.msi"
    Invoke-WebRequest -Uri $hostingUrl -OutFile $hostingMsi -UseBasicParsing
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$hostingMsi`" /qn /norestart"
    $hostingInstalled = $true
  } catch { Write-Warning "Hosting Bundle MSI install failed: $($_.Exception.Message)" }
}
if (-not $hostingInstalled) { throw "ASP.NET Core Hosting Bundle (8.x) failed to install." }

# ================== Node.js LTS (npm included) ==================
try { choco install nodejs-lts --no-progress -y | Out-Null }
catch { throw "Failed to install Node.js LTS via Chocolatey: $($_.Exception.Message)" }

# ================== MySQL 9.4 (Windows ZIP) — install only, no DB/user creation ==================
$mysqlZipUrl = "https://dev.mysql.com/get/Downloads/MySQL-9.4/mysql-9.4.0-winx64.zip"
$mysqlZip    = Join-Path $dl "mysql-9.4.0-winx64.zip"
$mysqlBase   = "C:\mysql"
$mysqlDir    = Join-Path $mysqlBase "mysql-9.4.0-winx64"
$mysqlData   = Join-Path $mysqlDir "data"
$mysqlIni    = "C:\ProgramData\MySQL\my.ini"

New-Item -Force -ItemType Directory -Path $mysqlBase,"C:\ProgramData\MySQL" | Out-Null

if (-not (Test-Path $mysqlZip)) {
  Invoke-WebRequest -Uri $mysqlZipUrl -OutFile $mysqlZip -UseBasicParsing
}

if (-not (Test-Path $mysqlDir)) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::ExtractToDirectory($mysqlZip, $mysqlBase)
}

@"
[mysqld]
basedir=$mysqlDir
datadir=$mysqlData
port=3306
bind-address=127.0.0.1
default_authentication_plugin=mysql_native_password
[mysql]
"@ | Set-Content -Encoding ASCII $mysqlIni

Push-Location (Join-Path $mysqlDir "bin")
if (!(Test-Path $mysqlData)) { New-Item -ItemType Directory -Path $mysqlData | Out-Null }
# Initialize system tables WITHOUT setting passwords or creating any app DBs/users
Start-Process -Wait -FilePath "$PWD\mysqld.exe" -ArgumentList "--defaults-file=$mysqlIni","--initialize-insecure","--console"
# Install service & start it
if (-not (Get-Service -Name "MySQL94" -ErrorAction SilentlyContinue)) {
  Start-Process -Wait -FilePath "$PWD\mysqld.exe" -ArgumentList "--install","MySQL94","--defaults-file=$mysqlIni"
}
Start-Service -Name "MySQL94"
Pop-Location

# Put MySQL bin on PATH (machine scope)
$envPath = [Environment]::GetEnvironmentVariable("Path","Machine")
if ($envPath -notlike "*$mysqlDir\bin*") {
  [Environment]::SetEnvironmentVariable("Path",$envPath + ";" + "$mysqlDir\bin","Machine")
}

# ================== IIS folders only (no app config) ==================
# Leave IIS site/app config to your deployment steps; these folders are where you'll deploy:
#   React build -> C:\inetpub\wwwroot\app
#   API publish -> C:\inetpub\wwwroot\api
# Open HTTP in Windows Firewall (SG still applies at AWS level)
netsh advfirewall firewall add rule name="HTTP" dir=in action=allow protocol=TCP localport=80 | Out-Null

Write-Host "----------------------------------------------------------------"
Write-Host "✅ Required software installed."
Write-Host "IIS + ANCM v2: installed"
Write-Host "Node.js LTS  : installed (npm included)"
Write-Host "MySQL 9.4    : installed as Windows service 'MySQL94' (no DB/users created)"
Write-Host "Folders      : UI -> $rootApp , API -> $rootApi"
Write-Host "Next steps   :"
Write-Host "  - Deploy React build to $rootApp"
Write-Host "  - Deploy 'dotnet publish' output (incl. web.config) to $rootApi"
Write-Host "  - Configure IIS app for /api if your deploy doesn't bring web.config"
Write-Host "  - Secure MySQL (set root password) and create your app DB/user when ready"
Write-Host "  - Access over http://<instance-public-dns>/  and /api once deployed"
Write-Host "----------------------------------------------------------------"
</powershell>

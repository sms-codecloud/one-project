<powershell>
# ================== Vars (inject with Terraform templatefile) ==================
$MYSQL_ROOT_PASSWORD = "${MYSQL_ROOT_PASSWORD}"   # required
$MYSQL_APP_PASSWORD  = "${MYSQL_APP_PASSWORD}"    # required
$APP_DB_NAME         = "StudentDb"
$APP_DB_USER         = "student_user"

# ================== Prep ==================
$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force

# Ensure TLS 1.2 for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create working dirs
$dl = "C:\_bootstrap\dl"; New-Item -Force -ItemType Directory -Path $dl | Out-Null
$rootApp = "C:\inetpub\wwwroot\app"
$rootApi = "C:\inetpub\wwwroot\api"
New-Item -Force -ItemType Directory -Path $rootApp,$rootApi | Out-Null

# ================== IIS + features ==================
Import-Module ServerManager
Add-WindowsFeature Web-Server, Web-WebSockets, Web-Static-Content, Web-Http-Redirect, Web-Http-Errors, Web-Http-Logging, Web-Http-Tracing, Web-Request-Monitor, Web-Mgmt-Tools | Out-Null

# ASP.NET Core Hosting Bundle (installs .NET runtime + AspNetCoreModuleV2 for IIS)
# Winget is not guaranteed on Windows Server, so we use the official Hosting Bundle MSI if available.
$dotnetPage = "https://dotnet.microsoft.com/en-us/download/dotnet/8.0"
# If you prefer a fixed bundle link, you can set $hostingUrl directly to that MSI.
$hostingUrl = "https://download.visualstudio.microsoft.com/download/pr/8b2f7c31-5d3a-4f6a-a3fa-xxxxxxxx/aspnetcore-runtime-8.0.x-windows-hosting-bundle-installer.msi"
try {
  # fallback if $hostingUrl wasn't updated to a fixed one
  if ($hostingUrl -like "*xxxxxxxx*") {
    # last resort: attempt winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
      winget install --id=Microsoft.DotNet.HostingBundle.8 -e --silent --accept-package-agreements --accept-source-agreements
      $hostingUrl = $null
    }
  }
  if ($hostingUrl) {
    $hostingMsi = Join-Path $dl "dotnet-hosting-bundle.msi"
    Invoke-WebRequest -Uri $hostingUrl -OutFile $hostingMsi -UseBasicParsing
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$hostingMsi`" /qn /norestart"
  }
} catch { Write-Warning "ASP.NET Core Hosting Bundle install attempted; verify manually if needed." }

# Optional: IIS URL Rewrite (helps SPA deep-linking). You can also bake rewrite rules in web.config.
# If you want the module, download the 2.1 x64 MSI and install silently, e.g.:
# $rewUrl = "https://download.microsoft.com/download/..../rewrite_amd64_en-US.msi"
# $rewMsi = Join-Path $dl "urlrewrite.msi"
# Invoke-WebRequest -Uri $rewUrl -OutFile $rewMsi -UseBasicParsing
# Start-Process msiexec.exe -Wait -ArgumentList "/i `"$rewMsi`" /qn /norestart"

# ================== AWS CLI v2 ==================
$awsMsi = Join-Path $dl "AWSCLIV2.msi"
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile $awsMsi -UseBasicParsing
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$awsMsi`" /qn /norestart"

# ================== MySQL 9.4 (Windows ZIP, no installer) ==================
# Source: MySQL 9.4 Windows x64 ZIP is officially available.
$mysqlZipUrl = "https://dev.mysql.com/get/Downloads/MySQL-9.4/mysql-9.4.0-winx64.zip"
$mysqlZip    = Join-Path $dl "mysql-9.4.0-winx64.zip"
$mysqlBase   = "C:\mysql"
$mysqlDir    = Join-Path $mysqlBase "mysql-9.4.0-winx64"
$mysqlData   = Join-Path $mysqlDir "data"
$mysqlIni    = "C:\ProgramData\MySQL\my.ini"

New-Item -Force -ItemType Directory -Path $mysqlBase,"C:\ProgramData\MySQL" | Out-Null
Invoke-WebRequest -Uri $mysqlZipUrl -OutFile $mysqlZip -UseBasicParsing

Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::ExtractToDirectory($mysqlZip, $mysqlBase)

# Create my.ini
@"
[mysqld]
basedir=$mysqlDir
datadir=$mysqlData
port=3306
bind-address=127.0.0.1
default_authentication_plugin=mysql_native_password
# optional: lower_case_table_names=1
[mysql]
"@ | Set-Content -Encoding ASCII $mysqlIni

# Initialize data dir (no password, we'll set it right after)
Push-Location (Join-Path $mysqlDir "bin")
if (!(Test-Path $mysqlData)) { New-Item -ItemType Directory -Path $mysqlData | Out-Null }
Start-Process -Wait -FilePath "$PWD\mysqld.exe" -ArgumentList "--defaults-file=$mysqlIni","--initialize-insecure","--console"

# Install as Windows service and start
Start-Process -Wait -FilePath "$PWD\mysqld.exe" -ArgumentList "--install","MySQL94","--defaults-file=$mysqlIni"
Start-Service -Name "MySQL94"
Pop-Location

# Set root password and create app DB/user
$mysqlExe = Join-Path $mysqlDir "bin\mysql.exe"
$secureSql = @"
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
CREATE DATABASE IF NOT EXISTS $APP_DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$APP_DB_USER'@'localhost' IDENTIFIED BY '$MYSQL_APP_PASSWORD';
GRANT ALL PRIVILEGES ON $APP_DB_NAME.* TO '$APP_DB_USER'@'localhost';
FLUSH PRIVILEGES;
"@
$secureSqlFile = Join-Path $dl "init.sql"
$secureSql | Set-Content -Encoding ASCII $secureSqlFile
& $mysqlExe -u root < $secureSqlFile

# Add MySQL bin to PATH for convenience
$envPath = [Environment]::GetEnvironmentVariable("Path","Machine")
if ($envPath -notlike "*$mysqlDir\bin*") {
  [Environment]::SetEnvironmentVariable("Path",$envPath + ";" + "$mysqlDir\bin","Machine")
}

# ================== IIS Site & Apps ==================
Import-Module WebAdministration

# Root site (Default Web Site) maps to UI
Set-ItemProperty "IIS:\Sites\Default Web Site" -Name physicalPath -Value $rootApp

# Create /api IIS application pointing to the published API folder
if (-not (Test-Path "IIS:\Sites\Default Web Site\api")) {
  New-WebApplication -Site "Default Web Site" -Name "api" -PhysicalPath $rootApi -ApplicationPool "DefaultAppPool" | Out-Null
}

# Basic spa-friendly web.config for UI (fallback to index.html)
$uiWebConfig = Join-Path $rootApp "web.config"
if (!(Test-Path $uiWebConfig)) {
@"
<?xml version=""1.0"" encoding=""utf-8""?>
<configuration>
  <system.webServer>
    <staticContent>
      <mimeMap fileExtension="".json"" mimeType=""application/json"" />
      <mimeMap fileExtension="".webp"" mimeType=""image/webp"" />
    </staticContent>
    <!-- If URL Rewrite module is installed, this fallback rule makes SPA routes work -->
    <rewrite>
      <rules>
        <rule name=""ReactRouterFallback"" stopProcessing=""true"">
          <match url=""^((?!api/).)*$"" />
          <conditions logicalGrouping=""MatchAll"">
            <add input=""{REQUEST_FILENAME}"" matchType=""IsFile"" negate=""true"" />
            <add input=""{REQUEST_FILENAME}"" matchType=""IsDirectory"" negate=""true"" />
          </conditions>
          <action type=""Rewrite"" url=""/index.html"" />
        </rule>
      </rules>
    </rewrite>
  </system.webServer>
</configuration>
"@ | Set-Content -Encoding UTF8 $uiWebConfig
}

# API folder placeholder web.config:
# (Your Jenkins publish output should include web.config created by dotnet publish for IIS/AspNetCoreModuleV2)
if (!(Test-Path (Join-Path $rootApi "web.config"))) {
@"
<?xml version=""1.0"" encoding=""utf-8""?>
<configuration>
  <system.webServer>
    <handlers>
      <add name=""aspNetCore"" path=""*"" verb=""*"" modules=""AspNetCoreModuleV2"" resourceType=""Unspecified"" />
    </handlers>
    <aspNetCore processPath=""dotnet"" arguments=""StudentApi.dll"" stdoutLogEnabled=""false"" hostingModel=""InProcess"" />
  </system.webServer>
</configuration>
"@ | Set-Content -Encoding UTF8 (Join-Path $rootApi "web.config")
}

# ================== Firewall & finish ==================
# Allow HTTP in Windows firewall (security group still governs inbound at AWS level)
netsh advfirewall firewall add rule name="HTTP" dir=in action=allow protocol=TCP localport=80

# Print helpful connection strings
Write-Host "MySQL connection strings:"
Write-Host "  Server=127.0.0.1;Port=3306;Database=$APP_DB_NAME;User=$APP_DB_USER;Password=$MYSQL_APP_PASSWORD;TreatTinyAsBoolean=false;SslMode=None"

Write-Host "Folders:"
Write-Host "  UI deploy to:  $rootApp"
Write-Host "  API deploy to: $rootApi (publish output incl. web.config)"

Write-Host "Bootstrap complete."
</powershell>

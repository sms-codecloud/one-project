pipeline {
  agent { label 'win-dev' }
  options { disableConcurrentBuilds(); timestamps() }

  parameters {
    // AWS & infra
    string( name: 'AWS_REGION',        defaultValue: 'ap-south-1',   description: 'AWS region' )
    string( name: 'EC2_INSTANCE_ID',   defaultValue: '',             description: 'Target Windows EC2 instance ID' )
    string( name: 'ARTIFACT_BUCKET',   defaultValue: 'arj-bootcamp', description: 'S3 bucket for deploy artifacts (web.zip & api.zip)' )

    // App layout
    string( name: 'APP_REL_PATH',      defaultValue: 'web',          description: 'Relative path to React app folder' )
    string( name: 'APP_NAME',          defaultValue: 'student-web',  description: 'Bundle name prefix for web.zip' )
    choice( name: 'NODE_MODE',         choices: ['production','development'], description: 'Runtime NODE_ENV (build forces dev for tooling)' )

    // Wiring frontend to backend (optional)
    string( name: 'API_BASE_URL',      defaultValue: '',             description: 'Optional API base URL exposed to React (e.g., http://localhost/api)' )

    // API artifact key (from API pipeline)
    string( name: 'API_S3_KEY',        defaultValue: '',             description: 'S3 key of api.zip from API pipeline (e.g., api/student-api-42.zip)' )

    // IIS configuration
    string( name: 'IIS_SITE_NAME',     defaultValue: 'one-project',  description: 'IIS site name' )
    string( name: 'IIS_SITE_ROOT',     defaultValue: 'C:\\deploy\\web', description: 'IIS site physical path (React)' )
    string( name: 'IIS_API_ROOT',      defaultValue: 'C:\\deploy\\api', description: 'IIS application physical path (API)' )
    string( name: 'IIS_APP_POOL',      defaultValue: 'one-project-app', description: 'App pool used by /api application' )
  }

  environment {
    NODE_ENV = "${params.NODE_MODE}"
    PATH     = "C:\\Program Files\\nodejs;C:\\Program Files\\Amazon\\AWSCLIV2;${env.PATH}"
    FORCED_WS = 'D:\\jenkins-workspace\\workspace'
  }

  stages {

    stage('Checkout (forced workspace)') {
      steps {
        ws("${env.FORCED_WS}") {
          deleteDir()
          checkout scm
          bat 'cd & dir /b'
        }
      }
    }

    stage('Prepare env for React (optional)') {
      when { expression { return params.API_BASE_URL?.trim() } }
      steps {
        ws("${env.FORCED_WS}") {
          dir("${params.APP_REL_PATH}") {
            // For Vite builds. Adjust if using CRA/custom.
            writeFile file: '.env.production', text: "VITE_API_BASE_URL=${params.API_BASE_URL}\r\n"
            echo "Wrote .env.production with VITE_API_BASE_URL=${params.API_BASE_URL}"
          }
        }
      }
    }

    stage('Install & Build (local)') {
      steps {
        ws("${env.FORCED_WS}") {
          dir("${params.APP_REL_PATH}") {
            // Ensure devDependencies for Vite/webpack tooling
            withEnv(['NODE_ENV=development','NPM_CONFIG_PRODUCTION=false']) {
              bat 'cmd /c node -v'
              bat 'cmd /c npm -v'
              bat 'cmd /c if exist package-lock.json (npm ci --include=dev) else (npm install)'
              bat 'cmd /c npm run build'
            }

            // Zip build output (Vite=dist, CRA=build)
            bat """
              if exist dist ( set "BUILD_DIR=dist" ) else ( set "BUILD_DIR=build" )
              for /f "tokens=* delims= " %%A in ("%BUILD_DIR%") do set "BUILD_DIR=%%~A"
              echo BUILD_DIR=[%BUILD_DIR%]
              if not exist "%BUILD_DIR%" ( echo ERROR: No dist/ or build/ folder.& exit /b 2 )
              if exist web.zip del /q web.zip
              powershell -NoProfile -ExecutionPolicy Bypass -Command ^
                "$bd = $env:BUILD_DIR.Trim(); Compress-Archive -Path (Join-Path $bd '*') -DestinationPath web.zip -Force"
              dir web.zip
            """
            archiveArtifacts artifacts: 'web.zip', fingerprint: true
          }
        }
      }
    }

    stage('Upload web.zip to S3') {
      steps {
        ws("${env.FORCED_WS}") {
          withCredentials([[$class:'AmazonWebServicesCredentialsBinding', credentialsId:'aws_secrets_shankar']]) {
            dir("${params.APP_REL_PATH}") {
              script {
                def key = "web/${params.APP_NAME}-${env.BUILD_NUMBER}.zip"
                bat "aws s3 cp web.zip s3://${params.ARTIFACT_BUCKET}/${key} --region ${params.AWS_REGION}"
                env.S3_KEY = key
                echo "Uploaded: s3://${params.ARTIFACT_BUCKET}/${key}"
              }
            }
          }
        }
      }
    }

    stage('Deploy both (web + api) to IIS via SSM') {
      when { expression { return params.EC2_INSTANCE_ID?.trim() } }
      steps {
        ws("${env.FORCED_WS}") {
          withCredentials([[$class:'AmazonWebServicesCredentialsBinding', credentialsId:'aws_secrets_shankar']]) {
            script {
              if (!params.API_S3_KEY?.trim()) {
                error "API_S3_KEY is required (the S3 key to api.zip from your API pipeline)."
              }

              // PowerShell to execute on EC2 (deploy web + api to IIS)
              def ps = """
$ErrorActionPreference = 'Stop'
Import-Module WebAdministration
aws --version | Out-Null

# Inputs
$region    = '${params.AWS_REGION}'
$bucket    = '${params.ARTIFACT_BUCKET}'
$webKey    = '${env.S3_KEY}'
$apiKey    = '${params.API_S3_KEY}'

$siteName  = '${params.IIS_SITE_NAME}'
$siteRoot  = '${params.IIS_SITE_ROOT.replace('\\','\\\\')}'
$apiRoot   = '${params.IIS_API_ROOT.replace('\\','\\\\')}'
$appPool   = '${params.IIS_APP_POOL}'

$inbox     = 'C:\\\\deploy\\\\incoming'
$webZip    = Join-Path $inbox 'web.zip'
$apiZip    = Join-Path $inbox 'api.zip'
$webTmp    = Join-Path $inbox 'web_unzip'
$apiTmp    = Join-Path $inbox 'api_unzip'

# Ensure folders
New-Item -ItemType Directory -Force -Path $inbox    | Out-Null
New-Item -ItemType Directory -Force -Path $siteRoot | Out-Null
New-Item -ItemType Directory -Force -Path $apiRoot  | Out-Null

# Fetch artifacts
if (Test-Path $webZip) { Remove-Item $webZip -Force }
if (Test-Path $apiZip) { Remove-Item $apiZip -Force }
aws s3 cp "s3://$bucket/$webKey" $webZip --region $region
aws s3 cp "s3://$bucket/$apiKey" $apiZip --region $region

# Unzip fresh
foreach ($p in @($webTmp,$apiTmp)) { if (Test-Path $p) { Remove-Item $p -Recurse -Force }; New-Item -ItemType Directory -Path $p | Out-Null }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($webZip, $webTmp)
[System.IO.Compression.ZipFile]::ExtractToDirectory($apiZip, $apiTmp)

# Stop site if exists
if (Get-Website -Name $siteName -ErrorAction SilentlyContinue) {
  Stop-WebSite -Name $siteName -ErrorAction SilentlyContinue
}

# Deploy WEB (React)
if (Test-Path $siteRoot) { Get-ChildItem -Path $siteRoot -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
Copy-Item "$webTmp\\*" $siteRoot -Recurse -Force

# SPA web.config fallback if missing
$spaConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <rule name="React SPA Fallback" stopProcessing="true">
          <match url=".*" />
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
            <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
          </conditions>
          <action type="Rewrite" url="/index.html" />
        </rule>
      </rules>
    </rewrite>
    <staticContent>
      <mimeMap fileExtension=".json" mimeType="application/json" />
    </staticContent>
  </system.webServer>
</configuration>
"@
if (-not (Test-Path (Join-Path $siteRoot 'web.config'))) {
  $spaConfig | Out-File -FilePath (Join-Path $siteRoot 'web.config') -Encoding UTF8 -Force
}

# Deploy API (published output with ASP.NET Core web.config inside)
if (Test-Path $apiRoot) { Get-ChildItem -Path $apiRoot -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
Copy-Item "$apiTmp\\*" $apiRoot -Recurse -Force

# Ensure App Pool (No Managed Code)
if (-not (Test-Path IIS:\\AppPools\\$appPool)) {
  New-Item IIS:\\AppPools\\$appPool | Out-Null
  Set-ItemProperty IIS:\\AppPools\\$appPool -Name managedRuntimeVersion -Value ''
  Set-ItemProperty IIS:\\AppPools\\$appPool -Name startMode -Value 'AlwaysRunning'
} else {
  Set-ItemProperty IIS:\\AppPools\\$appPool -Name managedRuntimeVersion -Value ''
}

# Ensure Site
if (-not (Get-Website -Name $siteName -ErrorAction SilentlyContinue)) {
  New-Website -Name $siteName -PhysicalPath $siteRoot -Port 80 -Force | Out-Null
} else {
  Set-ItemProperty IIS:\\Sites\\$siteName -Name physicalPath -Value $siteRoot
}

# Ensure /api application under the site
$apiAppPath = "IIS:\\Sites\\$siteName\\api"
if (-not (Test-Path $apiAppPath)) {
  New-WebApplication -Site $siteName -Name 'api' -PhysicalPath $apiRoot -ApplicationPool $appPool | Out-Null
} else {
  Set-ItemProperty $apiAppPath -Name physicalPath -Value $apiRoot
  Set-ItemProperty $apiAppPath -Name applicationPool -Value $appPool
}

# Permissions (read/execute for IIS_IUSRS)
& icacls $siteRoot /grant "IIS_IUSRS:(OI)(CI)RX" /T | Out-Null
& icacls $apiRoot  /grant "IIS_IUSRS:(OI)(CI)RX" /T | Out-Null

# Start site
Start-WebSite -Name $siteName

Write-Host "✓ Deployed web to $siteRoot and API to $apiRoot under site '$siteName' (/api)."
""".trim()

              // Build {"commands":[...]} JSON for SSM
              def lines   = ps.split(/\r?\n/)
              def escaped = lines.collect { it.replace("\\", "\\\\").replace("\"", "\\\"") }
              def json    = '{"commands":["' + escaped.join('","') + '"]}'
              writeFile file: 'params_both.json', text: json

              // --- Send command & capture clean CommandId ---
              def cmdId = bat(
                returnStdout: true,
                script: """
                  @echo off
                  for /f "usebackq delims=" %%I in (`aws ssm send-command ^
                    --instance-ids ${params.EC2_INSTANCE_ID} ^
                    --document-name AWS-RunPowerShellScript ^
                    --parameters file://params_both.json ^
                    --region ${params.AWS_REGION} ^
                    --cli-binary-format raw-in-base64-out ^
                    --query "Command.CommandId" --output text`) do (
                    echo %%I
                  )
                """
              ).trim()
              echo "SSM CommandId=${cmdId}"

              // --- Poll status until terminal ---
              String status = ''
              int maxLoops = 60
              for (int i = 0; i < maxLoops; i++) {
                status = bat(
                  returnStdout: true,
                  script: """
                    @echo off
                    aws ssm list-commands --command-id ${cmdId} --region ${params.AWS_REGION} --query "Commands[0].Status" --output text
                  """
                ).trim()
                echo "SSM status: ${status}"
                if (['Success','Failed','TimedOut','Cancelled'].contains(status)) break
                sleep time: 5, unit: 'SECONDS'
              }

              // --- Fetch stdout/stderr ---
              def ssmOut = bat(
                returnStdout: true,
                script: """
                  @echo off
                  aws ssm get-command-invocation ^
                    --command-id ${cmdId} ^
                    --instance-id ${params.EC2_INSTANCE_ID} ^
                    --region ${params.AWS_REGION} ^
                    --query "StandardOutputContent" --output text
                """
              )
              def ssmErr = bat(
                returnStdout: true,
                script: """
                  @echo off
                  aws ssm get-command-invocation ^
                    --command-id ${cmdId} ^
                    --instance-id ${params.EC2_INSTANCE_ID} ^
                    --region ${params.AWS_REGION} ^
                    --query "StandardErrorContent" --output text
                """
              )

              echo "----- SSM STDOUT -----\n${ssmOut}"
              if (ssmErr?.trim()) echo "----- SSM STDERR -----\n${ssmErr}"

              if (status != 'Success') {
                error "SSM command ${cmdId} completed with status=${status}"
              }
            }
          }
        }
      }
    }
  }

  post {
    success { echo "✅ Web + API deployed to IIS on the Windows EC2 (t2.micro) via SSM." }
    always  { echo "Done. Workspace used: ${env.FORCED_WS}" }
  }
}

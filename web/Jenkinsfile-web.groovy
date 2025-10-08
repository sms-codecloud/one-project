pipeline {
  agent { label 'win-dev' }
  options { disableConcurrentBuilds(); timestamps() }

  parameters {
    string(name: 'AWS_REGION',      defaultValue: 'ap-south-1',   description: 'AWS region')
    string(name: 'EC2_INSTANCE_ID', defaultValue: 'i-0654aed058988e693',             description: 'Target Windows EC2 instance ID')
    string(name: 'ARTIFACT_BUCKET', defaultValue: 'arj-bootcamp', description: 'S3 bucket for deploy artifacts')
    string(name: 'APP_REL_PATH',    defaultValue: 'web',          description: 'Relative path to React app folder')
    string(name: 'APP_NAME',        defaultValue: 'student-web',  description: 'Bundle name prefix')
    choice(name: 'NODE_MODE',       choices: ['production','development'], description: 'NODE_ENV')
    string(name: 'API_S3_KEY',      defaultValue: 'api/student-api-11.zip',             description: 'S3 key of api.zip from API pipeline')
    string(name: 'IIS_SITE_NAME',   defaultValue: 'one-project',  description: 'IIS site name')
    string(name: 'IIS_SITE_ROOT',   defaultValue: 'C:\\deploy\\web', description: 'IIS site path')
    string(name: 'IIS_API_ROOT',    defaultValue: 'C:\\deploy\\api', description: 'IIS API path')
    string(name: 'IIS_APP_POOL',    defaultValue: 'one-project-app', description: 'IIS app pool name')
  }

  environment {
    PATH      = "C:\\Program Files\\nodejs;C:\\Program Files\\Amazon\\AWSCLIV2;${env.PATH}"
    FORCED_WS = 'D:\\jenkins-workspace\\workspace'
  }

  stages {
    stage('Checkout') {
      steps {
        ws("${env.FORCED_WS}") {
          deleteDir()
          checkout scm
        }
      }
    }

    stage('Install & Build React') {
      steps {
        ws("${env.FORCED_WS}") {
          dir("${params.APP_REL_PATH}") {
            withEnv(['NODE_ENV=development','NPM_CONFIG_PRODUCTION=false']) {
              bat 'cmd /c node -v'
              bat 'cmd /c npm -v'
              bat 'cmd /c if exist package-lock.json (npm ci --include=dev) else (npm install)'
              bat 'cmd /c npm run build'
            }

            bat '''
              @echo off
              if exist web.zip del /q web.zip
              powershell -NoProfile -ExecutionPolicy Bypass -Command "$bd = if (Test-Path 'dist') { 'dist' } elseif (Test-Path 'build') { 'build' } else { $null }; if (-not $bd) { throw 'No dist/ or build/ folder found.' }; Compress-Archive -Path (Join-Path $bd '*') -DestinationPath 'web.zip' -Force"
              if not exist web.zip ( echo ERROR: web.zip not created.& exit /b 3 )
              dir web.zip
            '''
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
                echo "Uploaded s3://${params.ARTIFACT_BUCKET}/${key}"
              }
            }
          }
        }
      }
    }

    stage('Deploy to IIS via SSM (web + api)') {
      when { expression { return params.EC2_INSTANCE_ID?.trim() } }
      steps {
        ws("${env.FORCED_WS}") {
          withCredentials([[$class:'AmazonWebServicesCredentialsBinding', credentialsId:'aws_secrets_shankar']]) {
            script {
              if (!params.API_S3_KEY?.trim()) {
                error "API_S3_KEY is required (api.zip S3 key)."
              }

              def site     = params.IIS_SITE_NAME
              def siteRoot = params.IIS_SITE_ROOT.replace('\\','\\\\')
              def apiRoot  = params.IIS_API_ROOT.replace('\\','\\\\')
              def appPool  = params.IIS_APP_POOL
              def region   = params.AWS_REGION
              def bucket   = params.ARTIFACT_BUCKET
              def webKey   = env.S3_KEY
              def apiKey   = params.API_S3_KEY

              def cmds = [
                '$ErrorActionPreference = "Stop"',   // <-- FIXED: single-quoted Groovy string, inner ''Stop''

                'Import-Module WebAdministration',
                'aws --version | Out-Null',

                // variables (these lines are double-quoted because we want Groovy to inject the params;
                // note the backslash before $ to keep PowerShell variables, e.g. $region)
                "\$region='${region}'",
                "\$bucket='${bucket}'",
                "\$webKey='${webKey}'",
                "\$apiKey='${apiKey}'",
                "\$site='${site}'",
                "\$siteRoot='${siteRoot}'",
                "\$apiRoot='${apiRoot}'",
                "\$appPool='${appPool}'",
                "\$inbox='C:\\\\deploy\\\\incoming'",
                "\$wzip=Join-Path \$inbox 'web.zip'",
                "\$azip=Join-Path \$inbox 'api.zip'",
                "\$wtmp=Join-Path \$inbox 'web_unzip'",
                "\$atmp=Join-Path \$inbox 'api_unzip'",

                // ensure dirs & download
                'New-Item -ItemType Directory -Force -Path $inbox | Out-Null',
                'New-Item -ItemType Directory -Force -Path $siteRoot | Out-Null',
                'New-Item -ItemType Directory -Force -Path $apiRoot  | Out-Null',
                'if (Test-Path $wzip) { Remove-Item $wzip -Force }',
                'if (Test-Path $azip) { Remove-Item $azip -Force }',
                'aws s3 cp "s3://$bucket/$webKey" $wzip --region $region',
                'aws s3 cp "s3://$bucket/$apiKey" $azip --region $region',

                // unzip
                'Add-Type -AssemblyName System.IO.Compression.FileSystem',
                'if (Test-Path $wtmp) { Remove-Item $wtmp -Recurse -Force }',
                'if (Test-Path $atmp) { Remove-Item $atmp -Recurse -Force }',
                '[System.IO.Compression.ZipFile]::ExtractToDirectory($wzip,$wtmp)',
                '[System.IO.Compression.ZipFile]::ExtractToDirectory($azip,$atmp)',

                // stop site
                'if (Get-Website -Name $site -ErrorAction SilentlyContinue) { Stop-WebSite -Name $site -ErrorAction SilentlyContinue }',

                // deploy web
                'if (Test-Path $siteRoot) { Get-ChildItem -Path $siteRoot -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }',
                'Copy-Item "$wtmp\*" $siteRoot -Recurse -Force',

                // deploy api
                'if (Test-Path $apiRoot) { Get-ChildItem -Path $apiRoot -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }',
                'Copy-Item "$atmp\*" $apiRoot -Recurse -Force',

                // app pool & site
                'if (!(Test-Path IIS:\AppPools\$appPool)) { New-Item IIS:\AppPools\$appPool | Out-Null; Set-ItemProperty IIS:\AppPools\$appPool -Name managedRuntimeVersion -Value '''' } else { Set-ItemProperty IIS:\AppPools\$appPool -Name managedRuntimeVersion -Value '''' }',
                'if (!(Get-Website -Name $site -ErrorAction SilentlyContinue)) { New-Website -Name $site -PhysicalPath $siteRoot -Port 80 -Force | Out-Null } else { Set-ItemProperty IIS:\Sites\$site -Name physicalPath -Value $siteRoot }',
                '$apiApp = "IIS:\Sites\$site\api"',
                'if (!(Test-Path $apiApp)) { New-WebApplication -Site $site -Name ''api'' -PhysicalPath $apiRoot -ApplicationPool $appPool | Out-Null } else { Set-ItemProperty $apiApp -Name physicalPath -Value $apiRoot; Set-ItemProperty $apiApp -Name applicationPool -Value $appPool }',

                // permissions & start
                'icacls $siteRoot /grant "IIS_IUSRS:(OI)(CI)RX" /T | Out-Null',
                'icacls $apiRoot  /grant "IIS_IUSRS:(OI)(CI)RX" /T | Out-Null',
                'Start-WebSite -Name $site',
                'Write-Host "Deployed web+api to $site"'
              ]


              def payload = groovy.json.JsonOutput.toJson([parameters:[commands:cmds]])
              writeFile file: 'params.json', text: payload

              def cmdId = bat(returnStdout: true, script: "@echo off && aws ssm send-command --instance-ids ${params.EC2_INSTANCE_ID} --document-name AWS-RunPowerShellScript --parameters file://params.json --region ${params.AWS_REGION} --cli-binary-format raw-in-base64-out --query Command.CommandId --output text").trim()
              echo "CommandId=${cmdId}"

              sleep time: 10, unit: 'SECONDS'
              bat "aws ssm list-commands --command-id ${cmdId} --region ${params.AWS_REGION}"
            }
          }
        }
      }
    }
  }

  post {
    success { echo '✅ Deployment completed successfully.' }
    always { echo 'Pipeline finished.' }
  }
}

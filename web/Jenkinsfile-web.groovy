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
                "$ErrorActionPreference = 'Stop'",
                "Import-Module WebAdministration",
                "aws --version | Out-Null",
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
                "New-Item -ItemType Directory -Force -Path \$inbox | Out-Null",
                "aws s3 cp \"s3://\$bucket/\$webKey\" \$wzip --region \$region",
                "aws s3 cp \"s3://\$bucket/\$apiKey\" \$azip --region \$region",
                "Add-Type -AssemblyName System.IO.Compression.FileSystem",
                "[System.IO.Compression.ZipFile]::ExtractToDirectory(\$wzip,'C:\\\\deploy\\\\web')",
                "[System.IO.Compression.ZipFile]::ExtractToDirectory(\$azip,'C:\\\\deploy\\\\api')",
                "Import-Module WebAdministration",
                "Stop-WebSite -Name \$site -ErrorAction SilentlyContinue",
                "Start-WebSite -Name \$site",
                "Write-Host 'Deployed web+api successfully'"
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

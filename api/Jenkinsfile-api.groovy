pipeline {
  agent { label 'win-dev' }
  options { disableConcurrentBuilds(); timestamps() }

  parameters {
    string( name: 'AWS_REGION',        defaultValue: 'ap-south-1',     description: 'AWS region' )
    string( name: 'ARTIFACT_BUCKET',   defaultValue: 'arj-bootcamp',   description: 'S3 bucket to upload api.zip' )

    string( name: 'API_REL_PATH',      defaultValue: 'api',            description: 'Relative path to the .NET Web API project folder' )
    string( name: 'SLN_OR_CSPROJ',     defaultValue: 'StudentApi.csproj', description: 'Path to .sln or .csproj inside API_REL_PATH' )

    choice( name: 'CONFIGURATION',     choices: ['Release','Debug'],   description: 'Build configuration' )
    string( name: 'FRAMEWORK',         defaultValue: 'net8.0',         description: '.NET target framework (e.g., net8.0)' )
    string( name: 'RUNTIME',           defaultValue: 'win-x64',        description: 'Target runtime (e.g., win-x64)' )
    booleanParam( name: 'SELF_CONTAINED', defaultValue: false,         description: 'Publish self-contained? (false keeps artifact small for free tier)' )

    string( name: 'API_NAME',          defaultValue: 'student-api',    description: 'Name prefix for the artifact and S3 key (api/{API_NAME}-{BUILD_NUMBER}.zip)' )

    choice( name: 'ASPNETCORE_ENVIRONMENT', choices: ['Production','Development','Staging'], description: 'ASPNETCORE_ENVIRONMENT to embed into web.config (optional)' )
  }

  environment {
    PATH     = "C:\\Program Files\\Amazon\\AWSCLIV2;${env.PATH}"
    DOTNET_CLI_TELEMETRY_OPTOUT = '1'
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

    stage('Restore & Build') {
      steps {
        ws("${env.FORCED_WS}") {
          dir("${params.API_REL_PATH}") {
            bat 'dotnet --info'
            bat "dotnet restore \"${params.SLN_OR_CSPROJ}\""
            bat "dotnet build \"${params.SLN_OR_CSPROJ}\" -c ${params.CONFIGURATION} -f ${params.FRAMEWORK} --no-restore"
          }
        }
      }
    }

    stage('Test (optional)') {
      when { expression { return fileExists("${env.FORCED_WS}\\${params.API_REL_PATH}\\tests") } }
      steps {
        ws("${env.FORCED_WS}") {
          dir("${params.API_REL_PATH}") {
            bat "dotnet test -c ${params.CONFIGURATION} --no-build --verbosity normal"
          }
        }
      }
    }

    stage('Publish') {
      steps {
        ws("${env.FORCED_WS}") {
          dir("${params.API_REL_PATH}") {
            bat 'if exist publish rd /s /q publish'
            bat 'mkdir publish'
            bat "dotnet publish \"${params.SLN_OR_CSPROJ}\" -c ${params.CONFIGURATION} -f ${params.FRAMEWORK} -r ${params.RUNTIME} --self-contained=${params.SELF_CONTAINED} -o publish --no-build"
            bat 'if not exist publish\web.config (' +
                ' (echo ^<?xml version="1.0" encoding="utf-8"?^> ^> publish\web.config) ^&^& ' +
                ' (echo ^<configuration^>^<system.webServer^>^<handlers^>^<add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" /^>^</handlers^>^<aspNetCore processPath="dotnet" arguments="^%LAUNCHER_PATH^%" stdoutLogEnabled="false" hostingModel="InProcess" /^>^</system.webServer^>^</configuration^> ^>^> publish\web.config) )'
            bat "powershell -NoProfile -ExecutionPolicy Bypass -Command \"$wc = Get-Content -Raw publish\\web.config; if ('${params.ASPNETCORE_ENVIRONMENT}' -ne '') { if ($wc -notmatch 'environmentVariables') { $wc = $wc -replace '</aspNetCore>', '<environmentVariables><environmentVariable name=\"ASPNETCORE_ENVIRONMENT\" value=\"${params.ASPNETCORE_ENVIRONMENT}\" /></environmentVariables></aspNetCore>'; } else { $wc = $wc -replace '</environmentVariables>', '<environmentVariable name=\"ASPNETCORE_ENVIRONMENT\" value=\"${params.ASPNETCORE_ENVIRONMENT}\" /></environmentVariables>'; } Set-Content -Path publish\\web.config -Value $wc -Encoding UTF8 }""
            bat 'if exist api.zip del /q api.zip'
            bat 'powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path publish\* -DestinationPath api.zip -Force"'
            bat 'dir api.zip'
            archiveArtifacts artifacts: 'api\\api.zip', fingerprint: true
          }
        }
      }
    }

    stage('Upload api.zip to S3') {
      steps {
        ws("${env.FORCED_WS}") {
          withCredentials([[$class:'AmazonWebServicesCredentialsBinding', credentialsId:'aws_secrets_shankar']]) {
            dir("${params.API_REL_PATH}") {
              script {
                def key = "api/${params.API_NAME}-${env.BUILD_NUMBER}.zip"
                bat "aws s3 cp api.zip s3://${params.ARTIFACT_BUCKET}/${key} --region ${params.AWS_REGION}"
                echo "Uploaded: s3://${params.ARTIFACT_BUCKET}/${key}"
                currentBuild.displayName = "#${env.BUILD_NUMBER} ${params.API_NAME}"
                currentBuild.description  = "API_S3_KEY=${key}"
                writeFile file: 'API_S3_KEY.txt', text: key
                archiveArtifacts artifacts: 'API_S3_KEY.txt', fingerprint: true
              }
            }
          }
        }
      }
    }
  }

  post {
    success {
      echo "✅ API published and uploaded. Use API_S3_KEY in your web deploy job."
    }
    always {
      echo "Done. Workspace used: ${env.FORCED_WS}"
    }
  }
}
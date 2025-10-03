pipeline {
  agent { label 'dev-win' }   // ensure your agent label matches

  options { timestamps(); ansiColor('xterm') }
  triggers { githubPush() }   // or pollSCM('H/2 * * * *')

  environment {
    API_DIR    = 'api'
    WEB_DIR    = 'web'
    API_OUT    = 'api-publish'
    WEB_OUT    = 'web-dist'
    PKG_DIR    = 'deploy_pkg'
    PKG_ZIP    = 'deploy.zip'

    // --- Remote (EC2) ---
    REMOTE_HOST = 'ec2-xx-xx-xx-xx.ap-south-1.compute.amazonaws.com' // <- change me
    REMOTE_USER = 'ubuntu'
    REMOTE_TMP  = '/tmp/deploy'
    DEPLOY_API  = '/var/www/api'
    DEPLOY_WEB  = '/var/www/app'
    SERVICE     = 'studentapi'

    DOTNET_CLI_TELEMETRY_OPTOUT = '1'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Backend: Restore & Publish (.NET 8)') {
      steps {
        powershell """
          Set-Location ${env.API_DIR}
          dotnet --info
          dotnet restore
          dotnet build -c Release
          dotnet publish -c Release -o ..\\${env.API_OUT}
        """
      }
    }

    stage('Frontend: Build (React/Vite)') {
      steps {
        powershell """
          Set-Location ${env.WEB_DIR}
          if (Test-Path package-lock.json) { npm ci } else { npm install }
          npm run build
          New-Item -ItemType Directory -Force -Path ..\\${env.WEB_OUT} | Out-Null
          Copy-Item -Recurse -Force dist\\* ..\\${env.WEB_OUT}\\
        """
      }
    }

    stage('Package') {
      steps {
        powershell """
          Remove-Item -Recurse -Force ${env.PKG_DIR}, ${env.PKG_ZIP} -ErrorAction SilentlyContinue
          New-Item -ItemType Directory ${env.PKG_DIR}\\api, ${env.PKG_DIR}\\web | Out-Null
          Copy-Item -Recurse ${env.API_OUT}\\* ${env.PKG_DIR}\\api\\
          Copy-Item -Recurse ${env.WEB_OUT}\\* ${env.PKG_DIR}\\web\\
          Set-Content -Value ("buildTimestamp=" + (Get-Date).ToString("s")) -Path ${env.PKG_DIR}\\version.txt
          Compress-Archive -Path ${env.PKG_DIR}\\* -DestinationPath ${env.PKG_ZIP} -Force
        """
      }
    }

    stage('Transfer to EC2 via SSH/SCP') {
      steps {
        sshagent (credentials: ['ec2_ssh_key']) {
          // Upload bundle
          powershell """
            \$env:GIT_SSH_COMMAND = 'ssh -o StrictHostKeyChecking=no'
            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null `
              ${env.PKG_ZIP} ${env.REMOTE_USER}@${env.REMOTE_HOST}:/tmp/${env.PKG_ZIP}
          """
        }
      }
    }

    stage('Remote Deploy on EC2') {
      steps {
        sshagent (credentials: ['ec2_ssh_key']) {
          // Stop, unpack, swap, start, reload
          powershell """
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null `
                ${env.REMOTE_USER}@${env.REMOTE_HOST} `
                'set -euxo pipefail;
                 sudo systemctl stop ${env.SERVICE} || true;
                 rm -rf ${env.REMOTE_TMP} && mkdir -p ${env.REMOTE_TMP};
                 unzip -o /tmp/${env.PKG_ZIP} -d ${env.REMOTE_TMP};
                 sudo rm -rf ${env.DEPLOY_API}/* ${env.DEPLOY_WEB}/*;
                 sudo mkdir -p ${env.DEPLOY_API} ${env.DEPLOY_WEB};
                 sudo cp -r ${env.REMOTE_TMP}/api/* ${env.DEPLOY_API}/;
                 sudo cp -r ${env.REMOTE_TMP}/web/* ${env.DEPLOY_WEB}/;
                 sudo chown -R www-data:www-data ${env.DEPLOY_API} ${env.DEPLOY_WEB};
                 sudo systemctl daemon-reload;
                 sudo systemctl start ${env.SERVICE};
                 sudo systemctl enable ${env.SERVICE};
                 sudo nginx -t && sudo systemctl reload nginx;
                 rm -f /tmp/${env.PKG_ZIP};
                 rm -rf ${env.REMOTE_TMP};
                '
          """
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: "${API_OUT}/**/*, ${WEB_OUT}/**/*, ${PKG_ZIP}", allowEmptyArchive: true
    }
  }
}

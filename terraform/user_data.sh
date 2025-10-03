#!/usr/bin/env bash
set -euxo pipefail

# ---------- Base tools ----------
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common unzip git ufw

# ---------- Nginx ----------
apt-get install -y nginx
systemctl enable --now nginx

# ---------- Node.js (LTS 20) ----------
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# ---------- .NET 8 SDK ----------
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get update
apt-get install -y dotnet-sdk-8.0

# ---------- SQL Server 2022 Developer ----------
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
add-apt-repository "$(curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list)" -y
apt-get update
ACCEPT_EULA=Y apt-get install -y mssql-server
/opt/mssql/bin/mssql-conf -n set-sa-password
/opt/mssql/bin/mssql-conf set-sa-password <<< "$(printf "%s\n%s\n" "${SA_PASSWORD}" "${SA_PASSWORD}")" || true
/opt/mssql/bin/mssql-conf set sqlagent.enabled true
/opt/mssql/bin/mssql-conf set telemetry.customerfeedback false
systemctl enable --now mssql-server

# SQL tools + create database
curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/prod.list -o /etc/apt/sources.list.d/msprod.list
apt-get update
ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >/etc/profile.d/mssql.sh

/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -Q "IF DB_ID('StudentDb') IS NULL CREATE DATABASE StudentDb;"

# ---------- Jenkins (for CI on same box) ----------
apt-get install -y fontconfig openjdk-17-jre
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
  /usr/share/keyrings/jenkins-keyring.asc >/dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | tee \
  /etc/apt/sources.list.d/jenkins.list >/dev/null
apt-get update
apt-get install -y jenkins
systemctl enable --now jenkins

# ---------- App directories & permissions ----------
mkdir -p /var/www/app
mkdir -p /var/www/api
chown -R www-data:www-data /var/www
chmod -R 775 /var/www
usermod -aG www-data jenkins

# ---------- Nginx site ----------
cat >/etc/nginx/sites-available/app.conf <<'NGINX'
server {
    listen 80 default_server;
    server_name _;

    # React static
    root /var/www/app;
    index index.html;

    # Serve SPA
    location / {
        try_files $uri /index.html;
    }

    # API reverse proxy to Kestrel
    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX
rm -f /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/app.conf
nginx -t && systemctl reload nginx

# ---------- systemd for API ----------
cat >/etc/systemd/system/studentapi.service <<'UNIT'
[Unit]
Description=Student API (.NET 8, Kestrel)
After=network.target

[Service]
WorkingDirectory=/var/www/api
ExecStart=/usr/bin/dotnet /var/www/api/StudentApi.dll
Restart=always
RestartSec=5
User=www-data
Environment=ASPNETCORE_URLS=http://127.0.0.1:5000
Environment=ConnectionStrings__Default=Server=localhost,1433;Database=StudentDb;User ID=sa;Password=__SA_PASSWORD__;TrustServerCertificate=True;Encrypt=False

[Install]
WantedBy=multi-user.target
UNIT
sed -i "s/__SA_PASSWORD__/${SA_PASSWORD//\//\\/}/g" /etc/systemd/system/studentapi.service
systemctl daemon-reload

# ---------- Optional: clone your repo (first boot) ----------
if [ -n "${GITHUB_REPO_URL}" ]; then
  sudo -u jenkins git clone "${GITHUB_REPO_URL}" /var/lib/jenkins/workspace/seed-repo || true
fi

echo "DONE"

#!/usr/bin/env bash
set -euxo pipefail

# ========== Vars injected by Terraform ==========
SQL_SA_PASSWORD="${SQL_SA_PASSWORD:-ChangeMe123!Strong}"   # TF will inject

export DEBIAN_FRONTEND=noninteractive

# ---------- Base tools ----------
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common unzip git ufw

# ---------- Nginx ----------
apt-get install -y nginx
systemctl enable --now nginx

# ---------- Microsoft packages ----------
wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get update

# Install ONLY runtime needed to host published app (lighter than SDK)
apt-get install -y aspnetcore-runtime-8.0

# ---------- SQL Server 2022 Developer ----------
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
add-apt-repository -y "$(curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list)"
apt-get update
ACCEPT_EULA=Y apt-get install -y mssql-server

# Non-interactive setup: set SA password & accept EULA
ACCEPT_EULA=Y MSSQL_SA_PASSWORD="${SQL_SA_PASSWORD}" /opt/mssql/bin/mssql-conf -n setup

# SQL tools (sqlcmd) and path
curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/prod.list -o /etc/apt/sources.list.d/msprod.list
apt-get update
ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >/etc/profile.d/mssql.sh
source /etc/profile.d/mssql.sh

# Ensure service is up
systemctl enable --now mssql-server

# Create DB if not exists
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "${SQL_SA_PASSWORD}" -Q "IF DB_ID('StudentDb') IS NULL CREATE DATABASE StudentDb;"

# ---------- Web roots & perms ----------
mkdir -p /var/www/app
mkdir -p /var/www/api
chown -R www-data:www-data /var/www
chmod -R 775 /var/www

# ---------- Nginx site (SPA + reverse proxy) ----------
cat >/etc/nginx/sites-available/app.conf <<'NGINX'
server {
    listen 80 default_server;
    server_name _;

    # React static build
    root /var/www/app;
    index index.html;

    # SPA fallback
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

# ---------- systemd service for API ----------
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
Environment=ConnectionStrings__Default=Server=localhost,1433;Database=StudentDb;User ID=sa;Password=__SQL_SA_PASSWORD__;TrustServerCertificate=True;Encrypt=False

[Install]
WantedBy=multi-user.target
UNIT

# Inject SQL SA password into unit env
sed -i "s#__SQL_SA_PASSWORD__#${SQL_SA_PASSWORD}#g" /etc/systemd/system/studentapi.service
systemctl daemon-reload
# Do NOT start yet; Jenkins deploy will drop binaries then start:
# systemctl start studentapi

echo "Bootstrap complete."

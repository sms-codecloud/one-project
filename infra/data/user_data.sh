#!/usr/bin/env bash
set -euxo pipefail

# ===== Variables injected by Terraform =====
MYSQL_APP_PASSWORD="${MYSQL_APP_PASSWORD}"

export DEBIAN_FRONTEND=noninteractive

# ---------- Base packages ----------
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common unzip git ufw

# ---------- Nginx ----------
apt-get install -y nginx
systemctl enable --now nginx

# ---------- Install .NET 8 runtime ----------
wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get update
apt-get install -y aspnetcore-runtime-8.0

# ---------- Install MySQL Server (local DB for API) ----------
apt-get install -y mysql-server

# Bind only to localhost for safety (no external access)
sed -i 's/^[# ]*bind-address.*/bind-address = 127.0.0.1/' /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl enable --now mysql

# Create app database and user (avoid touching root plugin)
MYSQL_DB="studentdb"
MYSQL_USER="studentapp"
MYSQL_PWD="$MYSQL_APP_PASSWORD"

mysql --protocol=socket -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PWD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DB}\`.* TO '${MYSQL_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

# ---------- Folders ----------
mkdir -p /var/www/api
mkdir -p /var/www/app
chown -R www-data:www-data /var/www

# ---------- Systemd service for API ----------
cat >/etc/systemd/system/studentapi.service <<'UNIT'
[Unit]
Description=Student API
After=network.target

[Service]
WorkingDirectory=/var/www/api
ExecStart=/usr/bin/dotnet /var/www/api/StudentApi.dll
Restart=always
RestartSec=5
User=www-data
EnvironmentFile=/etc/studentapi.env
Environment=ASPNETCORE_URLS=http://127.0.0.1:5000

[Install]
WantedBy=multi-user.target
UNIT

# ---------- Connection string in env file ----------
cat >/etc/studentapi.env <<ENVVARS
ConnectionStrings__Default=Server=127.0.0.1;Port=3306;Database=studentdb;User Id=studentapp;Password=__SQL_APP_PASSWORD__;SslMode=Preferred
ENVVARS

# Inject app DB password into env file
sed -i "s#__SQL_APP_PASSWORD__#${MYSQL_APP_PASSWORD}#g" /etc/studentapi.env
chmod 600 /etc/studentapi.env
chown root:root /etc/studentapi.env

# ---------- Simple Nginx reverse proxy to Kestrel ----------
cat >/etc/nginx/sites-available/studentapp <<'NGX'
server {
    listen 80;
    server_name _;

    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        root /var/www/app;
        try_files $uri /index.html;
    }
}
NGX

ln -sf /etc/nginx/sites-available/studentapp /etc/nginx/sites-enabled/studentapp
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

# Enable service (Jenkins deploy will push binaries before starting)
systemctl daemon-reload
systemctl enable studentapi

echo "Bootstrap complete."

data "local_file" "schema" {
  filename = "${path.module}/db/schema.sql"
}

resource "null_resource" "apply_schema" {
  depends_on = [aws_db_instance.mysql]

  triggers = {
    schema_sha  = data.local_file.schema.content_sha256
    db_endpoint = aws_db_instance.mysql.address
    db_name     = var.db_name
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell","-NoProfile","-NonInteractive","-ExecutionPolicy","Bypass","-Command"]
    command = <<-POW
      $ErrorActionPreference = 'Stop'
      $host = "${aws_db_instance.mysql.address}"
      $user = "${var.db_username}"
      $pass = "${var.mysql_db_password}"
      $db   = "${var.db_name}"

      $tmp = Join-Path $env:TEMP "schema.sql"
      Set-Content -Path $tmp -Value @'
      ${data.local_file.schema.content}
      '@ -Encoding UTF8

      $env:Path = "$env:Path;C:\\Program Files\\MySQL\\MySQL Server 8.4\\bin;C:\\Program Files\\MySQL\\MySQL Server 8.0\\bin"
      & mysql.exe --host=$host --port=3306 --user=$user --password="$pass" --protocol=TCP -e "CREATE DATABASE IF NOT EXISTS \`$db\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci"
      if ($LASTEXITCODE -ne 0) { throw "MySQL create database failed." }

      & mysql.exe --host=$host --port=3306 --user=$user --password="$pass" --protocol=TCP $db < $tmp
      if ($LASTEXITCODE -ne 0) { throw "MySQL schema apply failed." }
    POW
  }
}

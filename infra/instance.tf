resource "random_string" "suffix" {
  length  = 5
  upper   = false
  lower   = true
  numeric = true
  special = false
}

# Windows instance with a public IP and IIS installed
resource "aws_instance" "win" {
  ami                         = data.aws_ami.windows.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = local.chosen_subnet_id
  vpc_security_group_ids      = [aws_security_group.one_project.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  # Minimal bootstrap (optional). Keep short to avoid long waits.
  # user_data = templatefile("${path.module}/data/user_data_windows.ps1", {
  #   MYSQL_ROOT_PASSWORD = var.mysql_root_password
  #   MYSQL_APP_PASSWORD  = var.mysql_app_password
  # })

  user_data = templatefile("${path.module}/data/new_user_data_rewrote.ps1", {
    MYSQL_ROOT_PASSWORD = var.mysql_root_password
    MYSQL_APP_PASSWORD  = var.mysql_app_password
  })

  tags = merge(var.tags, {
    Name = "one-project-win-${random_string.suffix.result}"
    Role = "web_api"
  })
}

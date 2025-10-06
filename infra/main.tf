resource "aws_security_group" "app" {
  name        = "single-ec2-nginx-mysql"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "one-project-ec2" }
}

resource "aws_instance" "app" {
  ami                         = "ami-0e6329e222e662a52"
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.app.id]
  subnet_id                   = element(data.aws_subnets.default.ids, 0)
  associate_public_ip_address = true   # <- important
  user_data = templatefile("${path.module}/data/user_data.sh", {
    MYSQL_DB = var.mysql_db, MYSQL_USER = var.mysql_user, MYSQL_APP_PASSWORD = var.mysql_app_password
  })
  tags = { Name = "one-project-ec2" }
}

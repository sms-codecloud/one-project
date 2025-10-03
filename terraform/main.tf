terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

provider "aws" { region = var.region }

# Latest Ubuntu 22.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "app" {
  name        = "single-ec2-nginx-sql-jenkins"
  description = "Allow SSH, HTTP, Jenkins"
  vpc_id      = data.aws_vpc.default.id

  ingress { description = "HTTP"  from_port = 80   to_port = 80   protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { description = "SSH"   from_port = 22   to_port = 22   protocol = "tcp" cidr_blocks = [var.my_ip_cidr] }
  ingress { description = "Jenkins" from_port = 8080 to_port = 8080 protocol = "tcp" cidr_blocks = [var.my_ip_cidr] }
  # SQL Server (local only) -> no external ingress for 1433

  egress  { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

data "aws_vpc" "default" { default = true }

resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app.id]

  user_data = templatefile("${path.module}/user_data.sh", {
    SA_PASSWORD     = var.sa_password
    GITHUB_REPO_URL = var.github_repo_url
  })

  tags = { Name = "single-ec2-nginx-dotnet-react-sql-jenkins" }
}

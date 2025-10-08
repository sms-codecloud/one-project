# --- Security Group: open HTTP to world, RDP is configurable (default: open) ---
resource "aws_security_group" "app" {
  name        = "${var.project}-sg"
  description = "Allow HTTP and (optionally) RDP"
  vpc_id      = var.vpc_id

  # HTTP for site
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RDP for admin (narrow this if possible)
  dynamic "ingress" {
    for_each = var.rdp_cidrs
    content {
      description = "RDP"
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project}-sg"
  })
}

# --- Windows EC2 instance (pulls latest AMI from the data source above) ---
resource "aws_instance" "app" {
  ami                         = data.aws_ami.windows_2022.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.app.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = var.iam_instance_profile # optional

  # Use your Windows PowerShell user_data
  user_data = templatefile("${path.module}/data/user_data_windows.ps1", {
    MYSQL_ROOT_PASSWORD = var.mysql_root_password
    MYSQL_APP_PASSWORD  = var.mysql_app_password
  })

  # Re-run user_data if its content changes
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required" # IMDSv2
  }

  tags = merge(var.common_tags, {
    Name = "${var.project}-ec2"
    OS   = "Windows-Server-2022"
  })
}


resource "aws_vpc" "this" {
  count      = local.use_existing_net ? 0 : 1
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "this" {
  count                   = local.use_existing_net ? 0 : 1
  vpc_id                  = local.use_existing_net ? null : aws_vpc.this[0].id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}
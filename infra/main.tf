# Basic SG allowing 80 & 3389 from the chosen CIDRs, and all egress
resource "aws_security_group" "app" {
  name        = "one-project-sg"
  description = "Allow HTTP and RDP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.http_cidr]
    description = "HTTP"
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.rdp_cidr]
    description = "RDP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description = "All egress"
  }

  tags = {
    Name = "one-project-sg"
  }
}

# IAM role + instance profile for SSM
resource "aws_iam_role" "ec2_ssm_role" {
  name = "one-project-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ssm" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "one-project-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# Windows EC2 instance in a random default subnet
resource "aws_instance" "app" {
  ami           = data.aws_ami.windows_2022.id
  instance_type = var.instance_type
  subnet_id     = local.selected_subnet_id
  key_name      = var.key_name != "" ? var.key_name : null

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  # Minimal bootstrap (optional). Keep short to avoid long waits.
 user_data = templatefile("${path.module}/data/user_data_windows.ps1", {
    MYSQL_ROOT_PASSWORD = var.mysql_root_password
    MYSQL_APP_PASSWORD  = var.mysql_app_password
  })

  tags = {
    Name = "one-project-windows"
  }
}

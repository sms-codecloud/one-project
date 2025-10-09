resource "aws_security_group" "one_project" {
  name        = "one-project-ec2-sg"
  description = "Allow HTTP 80 and RDP 3389 from the internet"
  vpc_id      = data.aws_vpc.default.id
  tags        = merge(var.tags, { Name = "one-project-ec2-sg" })

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.http_cidr]
  }

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.rdp_cidr]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG for RDS allows inbound 3306 from the EC2 SG (or from your existing EC2 SG if you pass it)
resource "aws_security_group" "rds_sg" {
  name        = "one-project-rds-sg"
  description = "RDS MySQL SG"
  vpc_id      = data.aws_vpc.default.id
}

# If example EC2 is created, allow from that SG
resource "aws_vpc_security_group_ingress_rule" "rds_from_example_ec2" {
  security_group_id            = aws_security_group.rds_sg.id
  description                 = "Allow MySQL from example EC2"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.one_project.id
}
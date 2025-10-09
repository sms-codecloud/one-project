resource "aws_db_subnet_group" "mysql" {
  name       = "one-project-mysql-subnets"
  subnet_ids = slice(data.aws_subnets.default_vpc_subnets.ids, 0, 2) # pick any 2 subnets
}

resource "random_password" "db_master" {
  length           = 20
  special          = true
  override_special = "!@#%^*-_+=?"
}

resource "aws_db_instance" "mysql" {
  identifier              = "one-project-mysql"
  engine                  = "mysql"
  engine_version          = "8.0"                  # keep broad for region compatibility
  instance_class          = "db.t3.micro"          # often free-tier eligible
  allocated_storage       = 20                     # free-tier typical size
  storage_type            = "gp3"                  # gp3 also fine in many regions
  db_name                 = var.db_name
  username                = var.db_username
  password                = random_password.db_master.result
  db_subnet_group_name    = aws_db_subnet_group.mysql.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = false                  # private; only EC2 in VPC can reach
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 1

  # Performance & timezone options can go in a parameter group if needed
}
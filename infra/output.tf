output "instance_id" {
  value       = aws_instance.win.id
  description = "EC2 instance ID"
}

output "public_ip" {
  value       = aws_instance.win.public_ip
  description = "Public IPv4 address"
}

output "public_dns" {
  value       = aws_instance.win.public_dns
  description = "Public DNS name"
}

output "subnet_id_used" {
  value       = aws_instance.win.subnet_id
  description = "Subnet ID associated with the instance / route table"
}

output "security_group_id" {
  value       = aws_security_group.one_project.id
  description = "Security group id"
}

output "mysql_endpoint" {
  value     = aws_db_instance.mysql.address
  sensitive = true
}

output "mysql_db_name" {
  value     = var.db_name
}

output "ssm_parameter_path" {
  value = aws_ssm_parameter.mysql_conn.name
}

output "ec2_profile_name" {
  value = aws_iam_instance_profile.ec2_profile.name
}
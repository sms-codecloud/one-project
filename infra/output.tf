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

# output "route_table_id" {
#   value       = aws_route_table.public.id
#   description = "Public route table id"
# }

output "vpc_id" {
  value = data.aws_vpc.default.id
    sensitive = false
}

output "subnet_id" {
  value = local.selected_subnet_id
    sensitive = false
}

output "security_group_id" {
  value = aws_security_group.app.id
    sensitive = false
}

output "instance_id" {
  value = aws_instance.app.id
    sensitive = false
}

output "instance_public_ip" {
  value = aws_instance.app.public_ip
    sensitive = false
}

output "instance_public_dns" {
  value = aws_instance.app.public_dns
    sensitive = false
}

output "windows_ami_id" {
  value = data.aws_ssm_parameter.win2022_ami.value
  sensitive = false
}

# --- Outputs ---
output "instance_public_ip" {
  value = aws_instance.app.public_ip
}

output "instance_public_dns" {
  value = aws_instance.app.public_dns
}

output "windows_ami_id" {
  value = data.aws_ami.windows_2022.id
}
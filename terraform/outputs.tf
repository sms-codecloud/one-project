output "ec2_public_ip" { value = aws_instance.app.public_ip }
output "app_url"       { value = "http://${aws_instance.app.public_dns}" }
output "jenkins_url"   { value = "http://${aws_instance.app.public_dns}:8080" }

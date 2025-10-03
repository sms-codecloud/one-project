output "ec2_public_ip" { 
    value = aws_instance.app.public_ip 
    description = "Public IP of the EC2 instance"
}

output "app_url"       { 
    value = "http://${aws_instance.app.public_dns}" 
    description = "URL of the application"
}

# output "jenkins_url"   { 
#     value = "http://${aws_instance.app.public_dns}:8080" 
#     description = "URL of the Jenkins server"
# }

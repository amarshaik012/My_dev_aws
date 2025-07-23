output "jenkins_instance_public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_instance_public_dns" {
  description = "Public DNS of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.public_dns
}

resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "jenkins-key"
  public_key = tls_private_key.jenkins_key.public_key_openssh
}

resource "local_file" "private_key" {
  content          = tls_private_key.jenkins_key.private_key_pem
  filename         = "${path.module}/jenkins-key.pem"
  file_permission  = "0600"
}

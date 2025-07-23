resource "aws_instance" "jenkins" {
  ami                         = "ami-0c02fb55956c7d316"  # Amazon Linux 2
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  key_name                    = aws_key_pair.generated_key.key_name
  associate_public_ip_address = true

  tags = {
    Name = "jenkins-ec2"
  }
}

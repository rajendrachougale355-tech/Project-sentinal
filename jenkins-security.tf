resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Allow Jenkins UI and SSH"
  vpc_id      = aws_vpc.sentinel_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # In production, restrict this to your IP
  }
#ssh access for maintenance - In production, restrict this to your IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins_server" {
  ami                    = "ami-07a00cf47dbbc844c" # ubuntu Linux 2
  instance_type          = "m7i-flex.large"             # Jenkins needs at least 4GB RAM
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = "Project_key"

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              sudo import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              sudo amazon-linux-extras install java-openjdk11 -y
              sudo apt install jenkins -y
              sudo systemctl enable jenkins
              sudo systemctl start jenkins
              EOF

  tags = { Name = "Sentinel-Jenkins-Master" }
}
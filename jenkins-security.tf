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
  instance_type          = "m7i-flex.large"        # Jenkins needs at least 4GB RAM
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = "Project_key"

  user_data = <<-EOF
              #!/bin/bash
             #!/bin/bash
sudo apt update -y
sudo apt install openjdk-11-jdk -y

# Add Jenkins repo
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install jenkins -y

sudo systemctl enable jenkins
sudo systemctl start jenkins

              EOF

  tags = { Name = "Sentinel-Jenkins-Master" }
}
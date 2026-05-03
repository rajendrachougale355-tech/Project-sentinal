
# 1. Fetch the latest Amazon Linux 2 AMI
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 2. Create the EC2 Instance in the Private Subnet
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_app_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "Project_key"
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install docker -y
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo systemctl restart docker
              # Log in to ECR (Replace with your ID)
              aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 556791123713.dkr.ecr.ap-south-1.amazonaws.com
              
              # Pull and Run the container
              docker pull 556791123713.dkr.ecr.ap-south-1.amazonaws.com/sentinel-app:v1
              docker run -d -p 80:80 556791123713.dkr.ecr.ap-south-1.amazonaws.com/sentinel-app:v1
              EOF
  tags = {
    Name = "Sentinel-App-Server"
  }
}




# Create a Bastion Host in the Public Subnet
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id # Lives in Public Subnet
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true # Needs a Public IP
  key_name                    = "Project_key"
  tags = {
    Name = "Sentinel-Bastion-Host"
  }
}



# 1. Create the Application Load Balancer (Public)
resource "aws_lb" "sentinel_alb" {
  name               = "sentinel-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_b.id] # Needs two AZs for High Availability

  tags = {
    Name = "Sentinel-ALB"
  }
}


# 2. Create the Target Group
resource "aws_lb_target_group" "sentinel_tg" {
  name     = "sentinel-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.sentinel_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 3. Create the Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.sentinel_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sentinel_tg.arn
  }
}

# 4. Attach your App Server to the Target Group
resource "aws_lb_target_group_attachment" "app_attach" {
  target_group_arn = aws_lb_target_group.sentinel_tg.arn
  target_id        = aws_instance.app_server.id
  port             = 80
}
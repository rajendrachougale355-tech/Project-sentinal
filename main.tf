# 1. Define the Provider
provider "aws" {
  region = "ap-south-1" # Mumbai Region
}

# 2. Create the VPC (The House)
resource "aws_vpc" "sentinel_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "Sentinel-VPC"
  }
}



resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.sentinel_vpc.id 
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Sentinel-Public-Subnet"
  }
  
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.sentinel_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-1b"
}

# 4. Create an Internet Gateway (The Door)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.sentinel_vpc.id

  tags = {
    Name = "Sentinel-IGW"
  }
}

# 5. Route Table (The Map)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.sentinel_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# 6. Associate Route Table with Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}



# 1. Create a Private Subnet for the App
resource "aws_subnet" "private_app_subnet" {
  vpc_id            = aws_vpc.sentinel_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Sentinel-Private-App"
  }
}

# 2. Create an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

# 3. Create the NAT Gateway (Lives in Public Subnet)
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "Sentinel-NAT-GW"
  }
}

# 4. Route Table for Private Subnet
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.sentinel_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
}

# 5. Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_app_subnet.id
  route_table_id = aws_route_table.private_rt.id
}



# 1. Web Security Group (Allows HTTP and SSH)
resource "aws_security_group" "web_sg" {
  name        = "sentinel-web-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.sentinel_vpc.id

  # Inbound: Allow HTTP (Port 80) from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound: Allow SSH (Port 22) - In a real bank, this would be restricted to your IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Outbound: Allow all traffic to the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Database Security Group (ONLY allows traffic from the Web SG)
resource "aws_security_group" "db_sg" {
  name        = "sentinel-db-sg"
  description = "Allow traffic only from Web Security Group"
  vpc_id      = aws_vpc.sentinel_vpc.id

  ingress {
    from_port       = 3306 # MySQL port
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] # This is the "Pro" move
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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
  key_name = "Project_key"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install docker -y
              sudo systemctl start docker
              sudo systemctl enable docker
              
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
  key_name = "Project_key"
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
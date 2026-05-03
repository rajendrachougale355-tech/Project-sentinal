
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
   map_public_ip_on_launch = true 
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

# New Private Subnet in a different Zone
resource "aws_subnet" "private_app_subnet-2" {
  vpc_id            = aws_vpc.sentinel_vpc.id
  cidr_block        = "10.0.4.0/24"          # Logic: Use a new unique IP range
  availability_zone = "ap-south-1b"           # Logic: Must be different from your 1st subnet

  tags = {
    Name                                           = "sentinel-private-2"
    "kubernetes.io/cluster/project-sentinel-eks" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
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

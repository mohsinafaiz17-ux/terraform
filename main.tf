# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# Public Subnet (AUTO AZ FIX)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  # ✅ Fix: use valid AZ dynamically
  availability_zone = "ap-south-1a"

  tags = {
    Name = "public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "ap-south-1a"

  tags = {
    Name = "private-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "igw"
  }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "public-rt"
  }
}

# Route
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Route Table Association
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group (VERY IMPORTANT)
resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

# EC2 Instance 1
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"   # ✅ REQUIRED
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "Terraform-Web"
  }
}


# S3 Bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "mohsina-terraform-bucket-123457"  # ⚠️ must be globally unique

  tags = {
    Name = "My-Terraform-Bucket"
  }
}


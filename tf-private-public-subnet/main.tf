# 创建 VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "My-VPC" }
}

# 创建 Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true # 启用自动分配公网 IP
  availability_zone       = "${var.aws_region}a"
  tags                    = { Name = "Public-Subnet" }
}

# 创建 Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.private_subnet_cidr
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_region}b"
  tags                    = { Name = "Private-Subnet" }
}

# 创建 Internet Gateway (IGW)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags   = { Name = "My-IGW" }
}

# 创建 Elastic IP (用于 NAT Gateway)
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# 创建 NAT Gateway (放在 Public Subnet)
resource "aws_nat_gateway" "nat_gw" {
  subnet_id     = aws_subnet.public_subnet.id
  allocation_id = aws_eip.nat_eip.id
  tags          = { Name = "My-NAT-GW" }
}

# 创建 Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id
  tags   = { Name = "Public-Route-Table" }
}

# 添加 Public Route（0.0.0.0/0 → IGW）
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# 关联 Public Subnet 到 Public Route Table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 创建 Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id
  tags   = { Name = "Private-Route-Table" }
}

# 添加 Private Route（0.0.0.0/0 → NAT Gateway）
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# 关联 Private Subnet 到 Private Route Table
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group for Public EC2 (Allow SSH)
resource "aws_security_group" "public" {
  name        = "public-sg"
  description = "Allow SSH from anywhere"
  vpc_id      = aws_vpc.my_vpc.id

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

# Security Group for Private EC2 (Allow SSH from Public Subnet)
resource "aws_security_group" "private" {
  name        = "private-sg"
  description = "Allow SSH from Public Subnet"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.public_subnet.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance in Public Subnet
resource "aws_instance" "public_ec2" {
  ami                    = "ami-053a45fff0a704a47" # Replace with your desired AMI ID
  instance_type          = "t2.micro"
  key_name               = "mykey01" # 指定 AWS Console 上已有的 Key Pair
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.public.id]

  tags = {
    Name = "public-ec2"
  }

  associate_public_ip_address = true
}

# EC2 Instance in Private Subnet
resource "aws_instance" "private_ec2" {
  ami                    = "ami-053a45fff0a704a47" # Replace with your desired AMI ID
  instance_type          = "t2.micro"
  key_name               = "mykey01" # 指定 AWS Console 上已有的 Key Pair
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private.id]

  tags = {
    Name = "private-ec2"
  }
}

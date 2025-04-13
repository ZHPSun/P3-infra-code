
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "mainvpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "mainvpc"
  }
}

resource "aws_security_group" "newsg" {
  vpc_id = aws_vpc.mainvpc.id
  name   = "newsg"
  tags = {
    Name = "newsg"

  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group_rule" "allow_ports" {
  for_each = {
    "ssh"     = 22
    "http"    = 80
    "https"   = 443
    "jenkins" = 8080
  }

  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  security_group_id = aws_security_group.newsg.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_instance" "ansible-server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = var.public_key_name
  user_data     = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install git -y
              git --version
              sudo yum install ansible -y
              ansible --version
              EOF
  tags = {
    Name = "ansible-server"
  }
}


resource "aws_instance" "jenkins-server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = var.public_key_name

  tags = {
    Name = "jenkins-server"
  }
}

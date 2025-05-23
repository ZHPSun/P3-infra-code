
data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
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
  for_each = var.ingress_ports

  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  security_group_id = aws_security_group.newsg.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_instance" "ansible-server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  key_name      = var.public_key_name
  user_data     = <<-EOF
              #!/bin/bash
              # 更新系统
              dnf update -y
              # 安装 EPEL 仓库（可选，提供额外工具）
              dnf install -y epel-release
              # 安装 Ansible（Amazon Linux 2023 的官方方式）
              dnf install -y ansible
              # 验证安装是否成功
              ansible --version
              EOF
  tags = {
    Name = "ansible-server"
  }
}


resource "aws_instance" "jenkins-server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  key_name      = var.public_key_name

  tags = {
    Name = "jenkins-server"
  }
}

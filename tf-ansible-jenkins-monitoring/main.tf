
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

data "aws_vpc" "default" {
  default = true
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id # Reference your VPC ID
  name   = "default"
}

resource "aws_security_group_rule" "allow_ports" {
  for_each = {
    "ssh"           = 22
    "http"          = 80
    "https"         = 443
    "jenkins"       = 8080
    "backend"       = 3001
    "prometheus"    = 9090
    "grafana"       = 3000
    "node-exporter" = 9100
  }

  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Allow SSH from anywhere (not safe for production)
  security_group_id = data.aws_security_group.default.id
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

resource "aws_instance" "backend-server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = var.public_key_name

  tags = {
    Name = "backend-server"
  }
}

resource "aws_instance" "prometheus-server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.medium"
  key_name      = var.public_key_name

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "prometheus-server"
  }
}

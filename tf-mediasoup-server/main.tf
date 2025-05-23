######################
# 1. Data Sources
######################

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

######################
# 2. Security Group Rule
######################

resource "aws_security_group_rule" "allow_ports" {
  for_each = {
    ssh           = 22
    http          = 80
    https         = 443
    node_exporter = 9100
  }

  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.default.id
}

######################
# 3. IAM Roles
######################

## 3.1 EC2 IAM Role + Instance Profile
resource "aws_iam_role" "codedeploy_ec2_role" {
  name = "CodeDeployEC2InstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "codedeploy_instance_profile" {
  name = "CodeDeployEC2InstanceProfile"
  role = aws_iam_role.codedeploy_ec2_role.name
}

resource "aws_iam_role_policy_attachment" "codedeploy_ec2_policy" {
  role       = aws_iam_role.codedeploy_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

## 3.2 CloudWatch Logs Policy (for EC2 role)
resource "aws_iam_policy" "cwlogs_policy" {
  name = "CloudWatchLogsForEC2"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cwlogs_attachment" {
  role       = aws_iam_role.codedeploy_ec2_role.name
  policy_arn = aws_iam_policy.cwlogs_policy.arn
}

## 3.3 CodeDeploy Service Role
resource "aws_iam_role" "codedeploy_service_role" {
  name = "CodeDeployServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codedeploy.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_service_policy" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

######################
# 4. CodeDeploy App & Deployment Group
######################

resource "aws_codedeploy_app" "my_app" {
  name             = "media-soup-1"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "my_group" {
  app_name              = aws_codedeploy_app.my_app.name
  deployment_group_name = "media-soup-group-1"
  service_role_arn      = aws_iam_role.codedeploy_service_role.arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "mediasoup-server"
    }
  }

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }
}

######################
# 5. EC2 Instance
######################

resource "aws_instance" "mediasoup_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  key_name               = var.public_key_name
  iam_instance_profile   = aws_iam_instance_profile.codedeploy_instance_profile.name
  vpc_security_group_ids = [data.aws_security_group.default.id]

  tags = {
    Name = "mediasoup-server"
  }
  user_data = <<-EOF
  #!/bin/bash
  set -xe
  exec > /var/log/user-data.log 2>&1

  dnf update -y
  dnf install -y ruby wget

  cd /home/ec2-user
  wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
  chmod +x ./install
  sudo ./install auto

  systemctl enable codedeploy-agent
  systemctl start codedeploy-agent
EOF

}

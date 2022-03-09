variable "tutor-ssh-key" {
  default     = "martivo-x220"
  type        = string
  description = "The AWS ssh key to use."
}

variable "aws-region" {
  default     = "eu-central-1"
  type        = string
  description = "The AWS Region to deploy EKS"
}


variable "node-instance-type" {
  default     = "t3.large"
  type        = string
  description = "Worker Node EC2 instance type"
}

provider "aws" {
  region = var.aws-region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.48.0"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.139.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
     "Name" = "eksperiment-vpc"
    }
}

data "aws_availability_zone" "a" {
  name = "${var.aws-region}a"
}


data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_ami" "ubuntu-server" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
      name   = "architecture"
      values = ["x86_64"]
  }
}


resource "aws_subnet" "public-a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.139.0.0/24"
  availability_zone_id = data.aws_availability_zone.a.zone_id
  map_public_ip_on_launch = true

  tags = {
     "Name" = "eksperiment-public-a"
    }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat-a" {
  vpc      = true
}

resource "aws_nat_gateway" "gw-a" {
  allocation_id = aws_eip.nat-a.id
  subnet_id     = aws_subnet.public-a.id
  depends_on = [aws_internet_gateway.gw]

  tags = {
    "Name" = "eksperiment-gw-a"
  }
}


resource "aws_route_table" "r-public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    "Name" = "eksperiment-r-public"
  }
}

resource "aws_route_table_association" "ra-public-a" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_route_table.r-public.id
}


resource "aws_subnet" "private-app-a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.139.4.0/24"
  availability_zone_id = data.aws_availability_zone.a.zone_id
  tags = {
     "Name" = "eksperiment-private-app-a"
    }
}




resource "aws_route_table" "r-private-a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw-a.id
  }
  tags = {
    Name = "eksperiment-r-private-a"
  }
}


resource "aws_route_table_association" "ra-app-a" {
  subnet_id      = aws_subnet.private-app-a.id
  route_table_id = aws_route_table.r-private-a.id
}



resource "aws_iam_role" "node" {
  name = "eksperiment-eks-node-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}


resource "aws_iam_instance_profile" "node" {
  name = "eksperiment-eks-node-instance-profile"
  role = aws_iam_role.node.name
}

resource "aws_security_group" "node" {
  name        = "eksperiment-eks-node-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    self = true
  }

  tags = {
     "Name" = "eksperiment-eks-node-sg"
    }
}


resource "aws_instance" "master" {
    ami           = data.aws_ami.ubuntu-server.id
    instance_type = var.node-instance-type
    subnet_id = aws_subnet.public-a.id
    vpc_security_group_ids = [aws_security_group.node.id]
    key_name = var.tutor-ssh-key
    iam_instance_profile = aws_iam_instance_profile.node.name
      root_block_device {
        volume_size = "100"
      }
      tags = {
        "Name" = "eksperiment-master"
      }
    depends_on = [aws_iam_role.node]
}



resource "aws_instance" "worker-a" {
    ami           = data.aws_ami.ubuntu-server.id
    instance_type = var.node-instance-type
    subnet_id = aws_subnet.public-a.id
    vpc_security_group_ids = [aws_security_group.node.id]
    key_name = var.tutor-ssh-key
    iam_instance_profile = aws_iam_instance_profile.node.name
      root_block_device {
        volume_size = "100"
      }
      tags = {
        "Name" = "eksperiment-worker-a"
      }
    depends_on = [aws_iam_role.node]
}



resource "aws_instance" "worker-b" {
    ami           = data.aws_ami.ubuntu-server.id
    instance_type = var.node-instance-type
    subnet_id = aws_subnet.public-a.id
    vpc_security_group_ids = [aws_security_group.node.id]
    key_name = var.tutor-ssh-key
    iam_instance_profile = aws_iam_instance_profile.node.name
      root_block_device {
        volume_size = "100"
      }

      tags = {
        "Name" = "eksperiment-worker-b"
      }
    depends_on = [aws_iam_role.node]
}




# EC2 Module
# This module creates EC2 instances to be used as control plane nodes for EKS

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Data sources for AMIs
data "aws_ami" "ubuntu_22_04_lts" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# AMI mapping
locals {
  ami_mapping = {
    ubuntu_22_04_lts = data.aws_ami.ubuntu_22_04_lts.id
  }

  selected_ami_id = local.ami_mapping[var.ami_type]
}

# Security Group for EKS Control Plane EC2
resource "aws_security_group" "eks_control_plane" {
  name_prefix = "${var.environment}-eks-control-plane-"
  vpc_id      = var.vpc_id
  description = "Security group for EKS control plane EC2 instance"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
    description = "SSH access"
  }

  # HTTP/HTTPS for kubectl proxy and web access
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
    description = "Kubectl proxy"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
    description = "Web access"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-control-plane-sg"
  })
}

# User data script for EKS control plane setup
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    eks_cluster_name   = var.eks_cluster_name
    aws_region         = var.aws_region
    kubernetes_version = var.eks_cluster_version
  }))
}

# EC2 Instance for EKS Control Plane
resource "aws_instance" "eks_control_plane" {
  ami                    = local.selected_ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.eks_control_plane.id]
  subnet_id              = var.subnet_id
  iam_instance_profile   = var.iam_instance_profile_name

  user_data_base64 = local.user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = var.volume_size
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-control-plane"
    Type = "EKS-Control-Plane"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Key Pair Module
# This module manages SSH key pairs for EC2 instances

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# AWS Key Pair
resource "aws_key_pair" "eks_control_plane" {
  key_name   = "${var.environment}-eks-control-plane-key"
  public_key = var.public_key

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-control-plane-key"
  })
}

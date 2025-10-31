# IAM Module
# This module creates IAM roles, policies, and users for EKS

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# IAM Role for EC2 EKS Control Plane
resource "aws_iam_role" "eks_control_plane" {
  name = "${var.environment}-eks-control-plane-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-control-plane-role"
  })
}

# IAM Policy for EKS Control Plane Management
resource "aws_iam_policy" "eks_control_plane_policy" {
  name        = "${var.environment}-eks-control-plane-policy"
  description = "Policy for EC2 instance to manage EKS cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:ListRoles",
          "iam:PassRole",
          "iam:GetOpenIDConnectProvider",
          "iam:CreateOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviders",
          "iam:TagOpenIDConnectProvider",
          "iam:UntagOpenIDConnectProvider",
          "iam:AddClientIDToOpenIDConnectProvider",
          "iam:RemoveClientIDFromOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProviderThumbprint",
          "iam:DeleteOpenIDConnectProvider",
          "iam:CreatePolicy",
          "iam:CreatePolicyVersion",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicies",
          "iam:ListPolicyVersions",
          "iam:DeletePolicy",
          "iam:DeletePolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:GetRole",
          "iam:GetRolePolicy"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:UpdateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          "cloudformation:DescribeStackEvents",
          "cloudformation:DescribeStackResources",
          "cloudformation:GetTemplate",
          "cloudformation:ValidateTemplate",
          "cloudformation:ListStacks",
          "cloudformation:ListStackResources"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateLaunchTemplateVersion",
          "ec2:DeleteLaunchTemplate",
          "ec2:DeleteLaunchTemplateVersions",
          "ec2:ModifyLaunchTemplate"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:CreateLaunchConfiguration",
          "autoscaling:DeleteLaunchConfiguration",
          "autoscaling:DescribeLaunchConfigurations"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/eks/*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::eks-*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::eks-*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-control-plane-policy"
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "eks_control_plane_policy_attachment" {
  role       = aws_iam_role.eks_control_plane.name
  policy_arn = aws_iam_policy.eks_control_plane_policy.arn
}

# Attach AWS managed policy for EC2 instance
resource "aws_iam_role_policy_attachment" "eks_control_plane_ec2_policy" {
  role       = aws_iam_role.eks_control_plane.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "eks_control_plane_profile" {
  name = "${var.environment}-eks-control-plane-profile"
  role = aws_iam_role.eks_control_plane.name

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-control-plane-profile"
  })
}

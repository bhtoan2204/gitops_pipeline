# EKS Module
# This module creates a minimal EKS cluster for development

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# EKS Cluster Service Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-cluster-role"
  })
}

# Attach required policies to EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Node Group Role
resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.environment}-eks-node-group-role"

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
    Name = "${var.environment}-eks-node-group-role"
  })
}

# Attach required policies to EKS node group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

# Security Group for EKS Cluster
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.environment}-eks-cluster-"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow VPC CIDR to reach EKS API (443) when using private endpoint
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow VPC to EKS API"
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-cluster-sg"
  })
}

# Security Group for EKS Nodes
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.environment}-eks-nodes-"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-nodes-sg"
  })
}

# # Launch Template for EKS Nodes
# resource "aws_launch_template" "eks_nodes" {
#   name_prefix   = "${var.environment}-eks-nodes-"
#   image_id      = data.aws_ssm_parameter.eks_node_ami.value
#   instance_type = var.node_instance_types[0]

#   vpc_security_group_ids = [aws_security_group.eks_nodes.id]

#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       volume_size = var.node_disk_size
#       volume_type = "gp3"
#       encrypted   = true
#     }
#   }

#   user_data = base64encode(templatefile("${path.module}/user_data.sh", {
#     cluster_name     = aws_eks_cluster.main.name
#     cluster_endpoint = aws_eks_cluster.main.endpoint
#     cluster_ca       = aws_eks_cluster.main.certificate_authority[0].data
#   }))

#   tag_specifications {
#     resource_type = "instance"
#     tags = merge(var.tags, {
#       Name = "${var.environment}-eks-node"
#     })
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # Get the latest EKS optimized AMI
# data "aws_ssm_parameter" "eks_node_ami" {
#   name = "/aws/service/eks/optimized-ami/${var.kubernetes_version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
# }

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.environment}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.allowed_cidr_blocks
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # Required to use EKS Access Entries/Policies
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  # Enable EKS Add-ons
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_cloudwatch_log_group.eks_cluster
  ]

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-cluster"
  })
}

# EKS Add-ons (managed by EKS)
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# CloudWatch Log Group for EKS Cluster
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.environment}-eks-cluster/cluster"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-cluster-logs"
  })
}

# EKS Node Group - Using managed EKS approach (no custom launch template)
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.environment}-eks-nodes"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.node_instance_types
  capacity_type  = var.capacity_type
  ami_type       = "AL2023_x86_64_STANDARD" # Amazon Linux 2023

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable_percentage = 25
  }

  disk_size = var.node_disk_size

  dynamic "remote_access" {
    for_each = var.node_ssh_key_name != null && trimspace(var.node_ssh_key_name) != "" ? [var.node_ssh_key_name] : []
    content {
      ec2_ssh_key               = remote_access.value
      source_security_group_ids = [aws_security_group.eks_cluster.id]
    }
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
    aws_eks_cluster.main,
  ]

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-nodes"
  })
}

# Grant cluster admin access to control-plane IAM role via EKS Access Entries
resource "aws_eks_access_entry" "control_plane_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.control_plane_admin_principal_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "control_plane_admin_policy" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.control_plane_admin_principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.control_plane_admin]
}

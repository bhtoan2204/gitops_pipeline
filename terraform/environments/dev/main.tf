terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    # S3 bucket for storing Terraform state
    bucket = "terraform-state-dev-demo"

    # Key path for the state file
    key = "dev/terraform.tfstate"

    # AWS region
    region = "ap-southeast-1"

    # Enable Terraform's native lockfile handling (replaces DynamoDB locking)
    dynamodb_table = "terraform-state-locks-dev"
    use_lockfile   = true

    # Enable encryption
    encrypt = true

    # Optional: AWS profile to use
    # profile = "default"
  }
}

# Common tags
locals {
  common_tags = {
    Environment = "dev"
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }

  # Allow overriding admin email/phone from env-provided vars
  contact_admin = merge(var.domain_contact, {
    email        = var.admin_email != null && var.admin_email != "" ? var.admin_email : var.domain_contact.email
    phone_number = var.admin_phone != null && var.admin_phone != "" ? var.admin_phone : var.domain_contact.phone_number
  })
}

# Provider configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

# Additional provider for Route53 Domains API (must be in us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  environment          = "dev"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway

  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  environment = "dev"
  tags        = local.common_tags
}

# Key Pair Module
module "keypair" {
  source = "../../modules/keypair"

  environment = "dev"
  public_key  = file("${path.module}/../../ssh/id_ed25519.pub")
  tags        = local.common_tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  environment         = "dev"
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = var.vpc_cidr
  private_subnet_ids  = module.vpc.private_subnet_ids
  kubernetes_version  = var.kubernetes_version
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_max_size       = var.node_max_size
  node_min_size       = var.node_min_size
  node_disk_size      = var.node_disk_size
  capacity_type       = var.capacity_type
  node_ssh_key_name   = module.keypair.key_name
  allowed_cidr_blocks = var.allowed_ssh_cidrs
  tags                = local.common_tags

  control_plane_admin_principal_arn = module.iam.eks_control_plane_role_arn
}

# EC2 Control Plane Module
module "ec2_control_plane" {
  source = "../../modules/ec2"

  environment               = "dev"
  ami_type                  = var.ami_type
  instance_type             = var.control_plane_instance_type
  key_name                  = module.keypair.key_name
  vpc_id                    = module.vpc.vpc_id
  subnet_id                 = module.vpc.public_subnet_ids[0]
  iam_instance_profile_name = module.iam.eks_control_plane_instance_profile_name
  allowed_ssh_cidrs         = var.allowed_ssh_cidrs
  volume_size               = var.control_plane_volume_size
  eks_cluster_name          = module.eks.cluster_name
  eks_cluster_version       = var.kubernetes_version
  aws_region                = var.aws_region
  tags                      = local.common_tags
}

module "route53" {
  source = "../../modules/route53"

  domain_name     = var.domain_name
  auto_renew      = true
  privacy_protect = true
  register_domain = false

  contact_admin      = local.contact_admin
  contact_registrant = local.contact_admin
  contact_tech       = local.contact_admin

  tags = local.common_tags

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

# EKS Outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_version" {
  description = "EKS cluster version"
  value       = module.eks.cluster_version
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

# EC2 Control Plane Outputs
output "control_plane_instance_id" {
  description = "ID of the EC2 control plane instance"
  value       = module.ec2_control_plane.instance_id
}

output "control_plane_public_ip" {
  description = "Public IP address of the EC2 control plane instance"
  value       = module.ec2_control_plane.instance_public_ip
}

output "control_plane_private_ip" {
  description = "Private IP address of the EC2 control plane instance"
  value       = module.ec2_control_plane.instance_private_ip
}

output "control_plane_public_dns" {
  description = "Public DNS name of the EC2 control plane instance"
  value       = module.ec2_control_plane.instance_public_dns
}

# SSH Connection Commands
output "ssh_connection_command" {
  description = "SSH command to connect to the EKS control plane EC2 instance as ubuntu user"
  value       = "ssh -i ssh/id_rsa ubuntu@${module.ec2_control_plane.instance_public_ip}"
}

# Key Pair Outputs
output "key_pair_name" {
  description = "Name of the AWS key pair"
  value       = module.keypair.key_name
}

# IAM Outputs
output "eks_control_plane_role_arn" {
  description = "ARN of the EKS control plane IAM role"
  value       = module.iam.eks_control_plane_role_arn
}

output "eks_control_plane_instance_profile_name" {
  description = "Name of the EKS control plane instance profile"
  value       = module.iam.eks_control_plane_instance_profile_name
}

# Outputs
output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "ec2_instance_id" {
  description = "EC2 control plane instance ID"
  value       = module.ec2_control_plane.instance_id
}

output "ec2_instance_public_ip" {
  description = "EC2 control plane instance public IP"
  value       = module.ec2_control_plane.instance_public_ip
}

output "ec2_instance_public_dns" {
  description = "EC2 control plane instance public DNS"
  value       = module.ec2_control_plane.instance_public_dns
}

output "ssh_command" {
  description = "SSH command to connect to EC2 instance"
  value       = "ssh -i ../../ssh/id_rsa ubuntu@${module.ec2_control_plane.instance_public_ip}"
}

output "ssh_command_eks_admin" {
  description = "SSH command to connect as eks-admin user"
  value       = "ssh -i ../../ssh/id_rsa eks-admin@${module.ec2_control_plane.instance_public_ip}"
}

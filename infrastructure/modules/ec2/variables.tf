variable "ami_type" {
  description = "Type of AMI to use for EC2 instance"
  type        = string
  default     = "ubuntu_22_04_lts"

  validation {
    condition = contains([
      "ubuntu_22_04_lts",
    ], var.ami_type)
    error_message = "AMI type must be one of the supported operating systems."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EC2 instance will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where EC2 instance will be created"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name for EC2 instance"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = length(var.allowed_ssh_cidrs) > 0 && alltrue([
      for cidr in var.allowed_ssh_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "Provide at least one valid CIDR block for SSH access."
  }
}

variable "volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster to manage"
  type        = string
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

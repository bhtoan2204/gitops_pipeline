# General Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "demo"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "dev-team"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

# EKS Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.32"
}

variable "node_instance_types" {
  description = "Instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "node_disk_size" {
  description = "Disk size for EKS nodes in GB"
  type        = number
  default     = 20
}

variable "capacity_type" {
  description = "Capacity type for EKS nodes (ON_DEMAND or SPOT)"
  type        = string
  default     = "SPOT"
}

# EC2 Control Plane Configuration
variable "ami_type" {
  description = "Type of AMI to use for EC2 control plane"
  type        = string
  default     = "ubuntu_22_04_lts"
}

variable "control_plane_instance_type" {
  description = "EC2 instance type for control plane"
  type        = string
  default     = "t3.micro"
}

variable "control_plane_volume_size" {
  description = "Size of the root volume for control plane in GB"
  type        = number
  default     = 8
}

# Security Configuration
variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to EC2 instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = length(var.allowed_ssh_cidrs) > 0 && alltrue([
      for cidr in var.allowed_ssh_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "Provide at least one valid CIDR block for SSH and EKS API access."
  }
}

# Domain registration
variable "domain_name" {
  description = "Domain name to register"
  type        = string
  default     = "toanbh.com"
}

variable "domain_contact" {
  description = "Contact info for domain registration (used for admin/registrant/tech)"
  type = object({
    first_name      = string
    last_name       = string
    contact_type    = string
    organization    = optional(string)
    address_line_1  = string
    address_line_2  = optional(string)
    city            = string
    state           = string
    country_code    = string
    zip_code        = string
    phone_number    = string
    email           = string
    fax             = optional(string)
  })
  default = {
    first_name     = "Toan"
    last_name      = "Banh"
    contact_type   = "PERSON"
    organization   = null
    address_line_1 = "Tan Phu"
    address_line_2 = null
    city           = "HCM"
    state          = "tân phú hồ chí minh"
    country_code   = "VN"
    zip_code       = "72009"
    phone_number   = "" # lay tu env
    email          = "" # lay tu env
    fax            = null
  }
}

variable "admin_email" {
  description = "Override admin contact email via env (TF_VAR_admin_email)"
  type        = string
  default     = null
}

variable "admin_phone" {
  description = "Override admin contact phone via env (TF_VAR_admin_phone)"
  type        = string
  default     = null
}

# EKS Development Setup

This infrastructure creates a minimal EKS cluster with an EC2 control plane for development purposes.

## Architecture

- **EKS Cluster**: Minimal configuration with 1-2 t3.medium nodes
- **EC2 Control Plane**: Ubuntu 22.04 LTS instance with kubectl, eksctl, and helm pre-installed
- **VPC**: Shared VPC with public and private subnets
- **IAM**: Least-privilege roles for EKS management
- **Security**: SSH access restricted to specified CIDR blocks

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.5 installed
3. SSH key pair generated in `./ssh/` directory

## Quick Start

1. **Setup Backend Infrastructure** (if not already done):
   ```bash
   cd backend-setup
   terraform init
   terraform apply
   ```

2. **Initialize Terraform**:
   ```bash
   make init
   ```

3. **Plan the deployment**:
   ```bash
   make plan
   ```

4. **Apply the configuration**:
   ```bash
   make apply
   ```

5. **Get SSH connection command**:
   ```bash
   make eks-connect
   ```

6. **Connect to control plane**:
   ```bash
   ssh -i ./ssh/id_ed25519 ubuntu@<public-ip>
   ```

7. **Update kubeconfig** (on the control plane):
   ```bash
   ./update-kubeconfig.sh
   ```

8. **Verify cluster access**:
   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

## Cost Optimization

This setup is optimized for development with minimal costs:

- **EKS Control Plane**: ~$73/month (fixed cost)
- **Node Group**: 1-2 t3.medium instances (~$30-60/month)
- **EC2 Control Plane**: 1 t3.medium instance (~$30/month)
- **NAT Gateway**: ~$45/month (if enabled)
- **Storage**: Minimal EBS volumes

**Total estimated cost**: ~$150-200/month

## Configuration

### Key Variables (in `environments/dev/variables.tf`):

- `node_instance_types`: Instance types for EKS nodes (default: ["t3.medium"])
- `node_desired_size`: Desired number of nodes (default: 1)
- `node_max_size`: Maximum number of nodes (default: 2)
- `node_min_size`: Minimum number of nodes (default: 1)
- `control_plane_instance_type`: EC2 instance type for control plane (default: "t3.medium")
- `allowed_ssh_cidrs`: CIDR blocks allowed to SSH (default: [])

### Cost Reduction Tips:

1. **Use Spot Instances**: Change `capacity_type` to "SPOT" in EKS module
2. **Smaller Instances**: Use t3.small or t3.micro for development
3. **Disable NAT Gateway**: Set `enable_nat_gateway = false` (limits private subnet internet access)
4. **Single AZ**: Use only one availability zone

## Security Features

- **IAM Roles**: Least-privilege access for EKS management
- **Security Groups**: Restricted SSH access to specified CIDR blocks
- **Private Subnets**: EKS nodes in private subnets
- **Encrypted Storage**: EBS volumes encrypted at rest
- **VPC**: Isolated network environment

## Backend Management

The infrastructure uses S3 and DynamoDB for remote state management:

- **S3 Bucket**: `terraform-state-dev-demo` (stores Terraform state)
- **DynamoDB Table**: `terraform-state-locks-dev` (prevents concurrent modifications)

### Backend Commands:
```bash
# Setup backend infrastructure (one-time)
cd backend-setup
terraform init
terraform apply

# Check backend status
cd backend-setup
terraform show
```

## Management Commands

```bash
# Check cluster status
make eks-status

# Get SSH connection command
make eks-connect

# Estimate costs
make cost-estimate

# Show all outputs
make output

# Destroy infrastructure
make destroy
```

## Troubleshooting

### Common Issues:

1. **SSH Key Not Found**: Ensure `./ssh/id_ed25519` and `./ssh/id_ed25519.pub` exist
2. **Permission Denied**: Check AWS credentials and IAM permissions
3. **Cluster Not Accessible**: Verify security groups and VPC configuration
4. **High Costs**: Review instance types and enable cost optimization features

### Useful Commands:

```bash
# Check Terraform state
cd environments/dev && terraform state list

# View detailed plan
cd environments/dev && terraform plan -detailed-exitcode

# Check AWS resources
aws eks list-clusters
aws ec2 describe-instances --filters "Name=tag:Type,Values=EKS-Control-Plane"
```

## Development Workflow

1. **Deploy**: `make apply`
2. **Connect**: `make eks-connect`
3. **Develop**: SSH to control plane and use kubectl/helm
4. **Cleanup**: `make destroy` when done

## Notes

- This setup is for **development only**
- Do not use in production without additional security hardening
- Monitor costs regularly
- Keep Terraform state secure
- Regularly update Kubernetes and tool versions

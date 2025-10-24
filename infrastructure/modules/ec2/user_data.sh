#!/bin/bash

# EKS Control Plane Setup Script
# This script installs and configures kubectl, aws-cli, and other tools needed for EKS management

set -e

# Update system
apt-get update
apt-get upgrade -y

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install additional useful tools
apt-get install -y \
    jq \
    git \
    curl \
    wget \
    unzip \
    htop \
    vim \
    nano \
    tree

# Create a non-root user for EKS management
useradd -m -s /bin/bash eks-admin
usermod -aG sudo eks-admin

# Create .kube directory for eks-admin user
mkdir -p /home/eks-admin/.kube
chown eks-admin:eks-admin /home/eks-admin/.kube

# Create a script to update kubeconfig
cat > /home/eks-admin/update-kubeconfig.sh << 'EOF'
#!/bin/bash
aws eks update-kubeconfig --region ${aws_region} --name ${eks_cluster_name}
EOF

chmod +x /home/eks-admin/update-kubeconfig.sh
chown eks-admin:eks-admin /home/eks-admin/update-kubeconfig.sh

# Create a helpful README
cat > /home/eks-admin/README.md << 'EOF'
# EKS Control Plane Management

This EC2 instance is configured to manage the EKS cluster.

## Quick Start

1. Update kubeconfig:
   ```bash
   ./update-kubeconfig.sh
   ```

2. Verify cluster access:
   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

3. Useful commands:
   ```bash
   # Get cluster info
   kubectl cluster-info
   
   # List all resources
   kubectl get all --all-namespaces
   
   # Access cluster via proxy
   kubectl proxy --port=8000
   ```

## Installed Tools

- kubectl: Kubernetes command-line tool
- eksctl: EKS command-line tool
- helm: Kubernetes package manager
- aws-cli: AWS command-line interface

## Notes

- The cluster is configured with minimal resources for development
- Node group uses t3.medium instances
- Only 1-2 nodes are running by default
EOF

chown eks-admin:eks-admin /home/eks-admin/README.md

# Set up bash completion for kubectl
echo 'source <(kubectl completion bash)' >> /home/eks-admin/.bashrc
echo 'alias k=kubectl' >> /home/eks-admin/.bashrc
echo 'complete -F __start_kubectl k' >> /home/eks-admin/.bashrc

# Create a systemd service to automatically update kubeconfig on boot
cat > /etc/systemd/system/eks-kubeconfig.service << EOF
[Unit]
Description=Update EKS kubeconfig
After=network.target

[Service]
Type=oneshot
User=eks-admin
ExecStart=/home/eks-admin/update-kubeconfig.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable eks-kubeconfig.service

# Log completion
echo "EKS Control Plane setup completed at $(date)" >> /var/log/eks-setup.log

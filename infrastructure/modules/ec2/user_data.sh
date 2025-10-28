#!/bin/bash

# EKS Control Plane Setup Script
# This script installs and configures kubectl, aws-cli, and other tools needed for EKS management

set -euo pipefail

# Log all output for troubleshooting
exec > >(tee -a /var/log/user-data.log) 2>&1

export DEBIAN_FRONTEND=noninteractive

# Simple retry helper for apt and downloads
retry() { for i in 1 2 3 4 5; do "$@" && return 0 || sleep 5; done; return 1; }

# Update system (avoid full upgrade during first boot to reduce lock/interruptions)
retry sudo apt-get update

# Install additional useful tools
retry sudo apt-get install -y \
    jq \
    git \
    curl \
    wget \
    unzip \
    htop \
    vim \
    nano \
    tree
    
# Install AWS CLI v2
retry curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install kubectl (install version matching cluster)
retry curl -fsSLo kubectl "https://dl.k8s.io/release/v${kubernetes_version}.0/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install eksctl
retry bash -c 'curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp'
sudo mv /tmp/eksctl /usr/local/bin

# Install helm
retry bash -c 'curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'

# Create a non-root user for EKS management
sudo useradd -m -s /bin/bash eks-admin
sudo usermod -aG sudo eks-admin

# Create .kube directory for eks-admin user
sudo mkdir -p /home/eks-admin/.kube
sudo chown eks-admin:eks-admin /home/eks-admin/.kube

# Create a script to update kubeconfig
sudo tee /home/eks-admin/update-kubeconfig.sh > /dev/null << 'SCRIPTEOF'
#!/bin/bash
sudo aws eks update-kubeconfig --region ${aws_region} --name ${eks_cluster_name}
SCRIPTEOF

sudo chmod +x /home/eks-admin/update-kubeconfig.sh
sudo chown eks-admin:eks-admin /home/eks-admin/update-kubeconfig.sh

# Create a helpful README
# cat > /home/eks-admin/README.md << 'EOF'
# # EKS Control Plane Management

# This EC2 instance is configured to manage the EKS cluster.

# ## Quick Start

# 1. Update kubeconfig:
#    ```bash
#    ./update-kubeconfig.sh
#    ```

# 2. Verify cluster access:
#    ```bash
#    kubectl get nodes
#    kubectl get pods --all-namespaces
#    ```

# 3. Useful commands:
#    ```bash
#    # Get cluster info
#    kubectl cluster-info
   
#    # List all resources
#    kubectl get all --all-namespaces
   
#    # Access cluster via proxy
#    kubectl proxy --port=8000
#    ```

# ## Installed Tools

# - kubectl: Kubernetes command-line tool
# - eksctl: EKS command-line tool
# - helm: Kubernetes package manager
# - aws-cli: AWS command-line interface

# ## Notes

# - The cluster is configured with minimal resources for development
# - Node group uses t3.medium instances
# - Only 1-2 nodes are running by default
# EOF

# chown eks-admin:eks-admin /home/eks-admin/README.md

# Set up bash completion for kubectl
echo 'source <(kubectl completion bash)' | sudo tee -a /home/eks-admin/.bashrc > /dev/null
echo 'alias k=kubectl' | sudo tee -a /home/eks-admin/.bashrc > /dev/null
echo 'complete -F __start_kubectl k' | sudo tee -a /home/eks-admin/.bashrc > /dev/null

# Ensure /usr/local/bin is in PATH for all users
echo 'export PATH=/usr/local/bin:$PATH' | sudo tee /etc/profile.d/10-localpath.sh > /dev/null
sudo chmod 0644 /etc/profile.d/10-localpath.sh

# Create a systemd service to automatically update kubeconfig on boot
sudo tee /etc/systemd/system/eks-kubeconfig.service > /dev/null << 'EOF'
[Unit]
Description=Update EKS kubeconfig
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=eks-admin
ExecStart=/home/eks-admin/update-kubeconfig.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable eks-kubeconfig.service

# Log completion
echo "EKS Control Plane setup completed at $(date)" | sudo tee -a /var/log/eks-setup.log > /dev/null

# Update kubeconfig
# sudo aws eks update-kubeconfig --region ap-southeast-1 --name dev-eks-cluster

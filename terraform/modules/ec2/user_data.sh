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

# Ensure kube directory for root
sudo mkdir -p /root/.kube

# Create a script to update kubeconfig (root)
sudo tee /usr/local/bin/update-kubeconfig.sh > /dev/null << 'SCRIPTEOF'
#!/bin/bash
set -euo pipefail
aws eks update-kubeconfig --region ${aws_region} --name ${eks_cluster_name}
SCRIPTEOF

sudo chmod +x /usr/local/bin/update-kubeconfig.sh

# Set up bash completion for kubectl (root)
echo 'source <(kubectl completion bash)' | sudo tee -a /root/.bashrc > /dev/null
echo 'alias k=kubectl' | sudo tee -a /root/.bashrc > /dev/null
echo 'complete -F __start_kubectl k' | sudo tee -a /root/.bashrc > /dev/null

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
User=root
ExecStart=/usr/local/bin/update-kubeconfig.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable eks-kubeconfig.service

# Log completion
echo "EKS Control Plane setup completed at $(date)" | sudo tee -a /var/log/eks-setup.log > /dev/null

# Start the service
sudo systemctl start eks-kubeconfig.service
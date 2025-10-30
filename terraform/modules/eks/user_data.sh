#!/bin/bash
set -o xtrace

# Install required packages
yum update -y
yum install -y awscli

# Configure kubelet
/etc/eks/bootstrap.sh ${cluster_name}

# Configure container runtime
echo '{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}' > /etc/docker/daemon.json

systemctl daemon-reload
systemctl restart docker
systemctl enable docker

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Configure kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Configure AWS CLI
mkdir -p /home/ec2-user/.aws
cat > /home/ec2-user/.aws/config << EOF
[default]
region = ap-southeast-1
output = json
EOF

# Set proper permissions
chown -R ec2-user:ec2-user /home/ec2-user/.aws
chmod 600 /home/ec2-user/.aws/config

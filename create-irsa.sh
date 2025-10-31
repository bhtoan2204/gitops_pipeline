# ==== Biến môi trường ====
export REGION=ap-southeast-1
export AWS_REGION=$REGION
export AWS_DEFAULT_REGION=$REGION
export CLUSTER_NAME=dev-eks-cluster
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Lấy OIDC issuer của cluster
export OIDC_ISSUER=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION \
  --query "cluster.identity.oidc.issuer" --output text)
# Cắt https:// để có host/path làm condition key
export OIDC_PROVIDER=${OIDC_ISSUER#https://}

echo "ACCOUNT_ID=$ACCOUNT_ID"
echo "OIDC_ISSUER=$OIDC_ISSUER"
echo "OIDC_PROVIDER=$OIDC_PROVIDER"

# ==== 1) Tạo IAM Role cho ALB Controller (IRSA) ====
# Trust policy: cho phép SA kube-system/aws-load-balancer-controller assume role
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:aud": "sts.amazonaws.com",
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }
  ]
}
EOF

# Tạo role (tên có thể đổi nếu bạn muốn)
aws iam create-role \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --assume-role-policy-document file://trust-policy.json

# Gắn policy đã tạo trước đó (bạn đã có arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy)
aws iam attach-role-policy \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy

# ==== 2) Tạo/annotate ServiceAccount trong cluster ====
kubectl create sa -n kube-system aws-load-balancer-controller 2>/dev/null || true
kubectl annotate sa -n kube-system aws-load-balancer-controller \
  eks.amazonaws.com/role-arn=arn:aws:iam::$ACCOUNT_ID:role/AmazonEKSLoadBalancerControllerRole \
  --overwrite

# ==== 3) Cài AWS Load Balancer Controller bằng Helm (dùng SA vừa annotate) ====
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Lấy VPC ID của cluster
export VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION \
  --query "cluster.resourcesVpcConfig.vpcId" --output text)

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set region=$REGION \
  --set vpcId=$VPC_ID \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Kiểm tra controller đã chạy
kubectl get deploy -n kube-system aws-load-balancer-controller
kubectl logs -n kube-system deploy/aws-load-balancer-controller --tail=50

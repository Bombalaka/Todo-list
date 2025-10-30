#!/bin/bash
# setup-ebs-csi.sh - Setup EBS CSI Driver for EKS
# Run this ONCE after creating your EKS cluster

set -e  # Exit on any error

CLUSTER_NAME="todolist"
REGION="eu-west-1"

echo "════════════════════════════════════════════════════════"
echo "  EBS CSI Driver Setup"
echo "════════════════════════════════════════════════════════"
echo ""

# Connect to cluster
echo "🔌 Connecting to EKS cluster..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
echo "   ✅ Connected"
echo ""

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "📋 AWS Account: $AWS_ACCOUNT_ID"

# Get OIDC info
OIDC_URL=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.identity.oidc.issuer" --output text)
OIDC_ID=$(echo $OIDC_URL | cut -d '/' -f 5)
echo "📋 OIDC ID: $OIDC_ID"
echo ""

# Create OIDC provider
echo "🔐 [1/3] Creating OIDC provider..."
if aws iam list-open-id-connect-providers | grep -q $OIDC_ID; then
    echo "        ℹ️  Already exists, skipping"
else
    aws iam create-open-id-connect-provider \
      --url $OIDC_URL \
      --client-id-list sts.amazonaws.com \
      --thumbprint-list "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
    echo "        ✅ Created"
fi
echo ""

# Create IAM role
ROLE_NAME="AmazonEKS_EBS_CSI_DriverRole"
echo "👤 [2/3] Creating IAM role..."

if aws iam get-role --role-name $ROLE_NAME &> /dev/null; then
    echo "        ℹ️  Already exists, skipping"
else
    cat > ./ebs-csi-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}:aud": "sts.amazonaws.com",
        "oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
      }
    }
  }]
}
EOF

    aws iam create-role \
      --role-name $ROLE_NAME \
      --assume-role-policy-document file://ebs-csi-trust-policy.json \
      --description "IAM role for EBS CSI Driver"
    
    aws iam attach-role-policy \
      --role-name $ROLE_NAME \
      --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy
    # clean up
    rm ./ebs-csi-trust-policy.json 
    echo "        ✅ Created"
fi
echo ""

# Install addon
echo "🚀 [3/3] Installing EBS CSI addon..."
if aws eks describe-addon --cluster-name $CLUSTER_NAME --region $REGION --addon-name aws-ebs-csi-driver &> /dev/null; then
    echo "        ℹ️  Already installed, skipping"
else
    aws eks create-addon \
      --cluster-name $CLUSTER_NAME \
      --region $REGION \
      --addon-name aws-ebs-csi-driver \
      --service-account-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}
    
    echo "        ⏳ Waiting for addon (2-3 minutes)..."
    aws eks wait addon-active \
      --cluster-name $CLUSTER_NAME \
      --region $REGION \
      --addon-name aws-ebs-csi-driver
    
    echo "        ✅ Installed"
fi
echo ""

# Verify
echo "🔍 Verifying installation..."
sleep 10

if kubectl get pods -n kube-system | grep -q ebs-csi; then
    echo "   ✅ EBS CSI pods running"
else
    echo "   ⚠️  Pods still starting (this is normal)"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✅ Setup Complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Next: Run ./deploy-eks-ecr.sh"
echo ""
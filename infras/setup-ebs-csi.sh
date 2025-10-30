#!/bin/bash
# setup-ebs-csi.sh - One-time setup for EBS CSI Driver
# Run this ONCE after creating your EKS cluster

CLUSTER_NAME="todolist"
REGION="eu-west-1"

echo "═══════════════════════════════════════════"
echo "  EBS CSI Driver Setup for EKS"
echo "═══════════════════════════════════════════"
echo ""
echo "This script will:"
echo "  1. Create OIDC provider"
echo "  2. Create IAM role for EBS CSI"
echo "  3. Install EBS CSI Driver addon"
echo ""
read -p "Continue? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi
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
echo "🔐 Creating OIDC provider..."
if aws iam list-open-id-connect-providers | grep -q $OIDC_ID; then
    echo "   ℹ️  Already exists"
else
    aws iam create-open-id-connect-provider \
      --url $OIDC_URL \
      --client-id-list sts.amazonaws.com \
      --thumbprint-list "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
    echo "   ✅ Created"
fi
echo ""

# Create IAM role
ROLE_NAME="AmazonEKS_EBS_CSI_DriverRole"
echo "👤 Creating IAM role: $ROLE_NAME..."

if aws iam get-role --role-name $ROLE_NAME &> /dev/null; then
    echo "   ℹ️  Already exists"
else
    # Trust policy
    cat > /tmp/trust-policy.json <<EOF
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
      --assume-role-policy-document file:///tmp/trust-policy.json
    
    aws iam attach-role-policy \
      --role-name $ROLE_NAME \
      --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy
    
    rm /tmp/trust-policy.json
    echo "   ✅ Created"
fi
echo ""

# Install addon
echo "🚀 Installing EBS CSI Driver addon..."
if aws eks describe-addon --cluster-name $CLUSTER_NAME --region $REGION --addon-name aws-ebs-csi-driver &> /dev/null; then
    echo "   ℹ️  Already installed"
else
    aws eks create-addon \
      --cluster-name $CLUSTER_NAME \
      --region $REGION \
      --addon-name aws-ebs-csi-driver \
      --service-account-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}
    
    echo "   ⏳ Waiting for addon to be active..."
    aws eks wait addon-active \
      --cluster-name $CLUSTER_NAME \
      --region $REGION \
      --addon-name aws-ebs-csi-driver
    
    echo "   ✅ Installed"
fi
echo ""

echo "✅ EBS CSI Driver setup complete!"
echo ""
echo "You can now deploy applications that use persistent storage."
#!/bin/bash
REGION="eu-west-1"
CLUSTER_NAME="todolist"
NAMESPACE="todo-app-list"
IAM_ROLE_NAME="AmazonEKS_EBS_CSI_DriverRole"

echo "🗑️  AWS Cleanup"
read -p "Delete everything? (yes/no): " -r
[[ ! $REPLY == "yes" ]] && exit 0

# 1. Clean Kubernetes
if aws eks describe-cluster --name todolist --region $REGION &>/dev/null; then
    echo "Cleaning Kubernetes..."
    aws eks update-kubeconfig --region $REGION --name todolist
    helm uninstall todo-app-list -n todo-app-list 2>/dev/null || true
    kubectl delete pvc --all -n todo-app-list 2>/dev/null || true
    kubectl delete namespace todo-app-list 2>/dev/null || true
    sleep 30
fi

# 2. Delete EKS
echo "Deleting EKS..."
aws cloudformation delete-stack --stack-name todo-eks --region $REGION 2>/dev/null
aws cloudformation wait stack-delete-complete --stack-name todo-eks --region $REGION 2>/dev/null

# 3. Delete IAM Role
echo "Deleting IAM role..."
aws iam detach-role-policy --role-name AmazonEKS_EBS_CSI_DriverRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy 2>/dev/null || true
aws iam delete-role --role-name AmazonEKS_EBS_CSI_DriverRole 2>/dev/null || true

# 4. Delete VPC
echo "Deleting VPC..."
aws cloudformation delete-stack --stack-name todo-vpc --region $REGION 2>/dev/null
aws cloudformation wait stack-delete-complete --stack-name todo-vpc --region $REGION 2>/dev/null

# 5. Delete ECR
echo "Deleting ECR..."
aws cloudformation delete-stack --stack-name todo-ecr --region $REGION 2>/dev/null
aws cloudformation wait stack-delete-complete --stack-name todo-ecr --region $REGION 2>/dev/null

echo "✅ Done!"
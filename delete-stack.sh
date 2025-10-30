#!/bin/bash
# delete-all-stacks.sh - Delete all infrastructure stacks

REGION="eu-west-1"

echo "🗑️  Deleting all infrastructure stacks..."
echo "⚠️  This will delete EVERYTHING!"
echo ""

read -p "Are you sure? (yes/no): " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo ""

# Step 1: Delete EKS Stack FIRST (depends on VPC)
echo "🗑️  [1/3] Deleting EKS Stack..."
aws cloudformation delete-stack \
  --stack-name todo-eks \
  --region $REGION

echo "   ⏳ Waiting for EKS stack deletion (10-15 minutes)..."
aws cloudformation wait stack-delete-complete \
  --stack-name todo-eks \
  --region $REGION

echo "   ✅ EKS Stack deleted"
echo ""

# Step 2: Delete VPC Stack SECOND (was created first)
echo "🗑️  [2/3] Deleting VPC Stack..."
aws cloudformation delete-stack \
  --stack-name todo-vpc \
  --region $REGION

echo "   ⏳ Waiting for VPC stack deletion..."
aws cloudformation wait stack-delete-complete \
  --stack-name todo-vpc \
  --region $REGION

echo "   ✅ VPC Stack deleted"
echo ""

# Step 3: Delete ECR Stack (can be anytime)
#echo "🗑️  [3/3] Deleting ECR Stack..."
#aws cloudformation delete-stack \
#  --stack-name todolist-ecr \
#  --region $REGION

#echo "   ⏳ Waiting for ECR stack deletion..."
#aws cloudformation wait stack-delete-complete \
#  --stack-name todolist-ecr \
#  --region $REGION

echo "   ✅ ECR Stack deleted"
echo ""

echo "════════════════════════════════════════════"
echo "  ✅ All stacks deleted successfully!"
echo "════════════════════════════════════════════"
#!/bin/bash
# File: deploy-all-stacks.sh

echo "🚀 Deploying all CloudFormation stacks..."

# Step 1: VPC
echo "📡 Creating VPC..."
aws cloudformation create-stack \
  --stack-name todo-vpc \
  --template-body file://infras/Cloudformation/vpc.yaml \
  --region eu-west-1

aws cloudformation wait stack-create-complete --stack-name todo-vpc --region eu-west-1
echo "✅ VPC created"

# Step 2: ECR (if deleted)
# echo "📦 Creating ECR..."
# aws cloudformation create-stack \
#   --stack-name todo-ecr \
#   --template-body file://infras/Cloudformation/ecr.yaml \
#   --region eu-west-1
# aws cloudformation wait stack-create-complete --stack-name todo-ecr --region eu-west-1
# echo "✅ ECR created"

# Step 3: EKS
echo "☸️  Creating EKS cluster..."
aws cloudformation create-stack \
  --stack-name todo-eks \
  --template-body file://infras/Cloudformation/eks.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region eu-west-1

aws cloudformation wait stack-create-complete --stack-name todo-eks --region eu-west-1
echo "✅ EKS created"

# Step 4: Update kubectl config
aws eks update-kubeconfig --region eu-west-1 --name todolist

echo "🎉 All stacks deployed! Ready to work!"
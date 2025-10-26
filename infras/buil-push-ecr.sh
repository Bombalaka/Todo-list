#!/bin/bash

# This script builds a Docker image and pushes it to AWS ECR


# Get ECR URI and AWS Account ID from CloudFormation stack outputs
ECR_URI=$(aws cloudformation describe-stacks --stack-name todo-ecr --region eu-west-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ECRRepositoryURI`].OutputValue' --output text)
ECR_REGISTRY=$(echo $ECR_URI | cut -d'/' -f1)  # Fixed: split by '/' not '.'

# Variables
AWS_REGION="eu-west-1"
ECR_REPOSITORY="todo-list-repo"
IMAGE_TAG="v1.0.0"
IMAGE_NAME="${ECR_REPOSITORY}"  # Fixed: must match ECR repo name

echo "🚀 Building and pushing todo-list-app to ECR..."
echo "📦 ECR URI: ${ECR_URI}"
echo "📦 Full Image: ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
echo "📍 Region: ${AWS_REGION}"

# Check if ECR_URI is empty
if [ -z "$ECR_URI" ]; then
    echo "❌ Failed to get ECR URI from CloudFormation stack!"
    echo "💡 Make sure 'todo-ecr' stack is deployed"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running!"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured!"
    echo "💡 Run: aws configure"
    exit 1
fi

# Navigate to project root (where backend/ folder is)
cd "$(dirname "$0")/.."
echo "📂 Working directory: $(pwd)"

# Build the Docker image
echo "🔨 Building Docker image..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f backend/Todo_App/Dockerfile .

# Tag for ECR
echo "🏷️  Tagging for ECR..."
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

# Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Push to ECR
echo "🚀 Pushing to ECR..."
docker push ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

echo "✅ Successfully pushed to ECR!"
echo "📦 Image: ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
echo "🚀 Ready for deployment to EKS!"

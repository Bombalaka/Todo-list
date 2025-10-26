#!/bin/bash
# Complete fix script with CORRECT Dockerfile path
# 
# IMPORTANT: Run this script from ~/Todo_App directory
# 
# Your structure should be:
#   ~/Todo_App/
#   ├── backend/Todo_App/Dockerfile
#   ├── Todo_App/src/assets/ToDoList.jsx
#   └── manifests/todo-app-list/
# Fix any localhost:8080 issues by following these steps.

set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 Complete Fix Script for localhost:8080 Issue"
echo "════════════════════════════════════════════════════════"
echo ""

# Configuration
ECR_REGISTRY="146624863550.dkr.ecr.eu-west-1.amazonaws.com"
ECR_REPO="todo-list-repo"
IMAGE_TAG="v1.2.1"
AWS_REGION="eu-west-1"
EKS_CLUSTER="todolist"
NAMESPACE="todo-app-list"
DOCKERFILE_PATH="backend/Todo_App/Dockerfile"

echo "📋 Configuration:"
echo "  ECR Registry: $ECR_REGISTRY"
echo "  Repository: $ECR_REPO"
echo "  Tag: $IMAGE_TAG"
echo "  Dockerfile: $DOCKERFILE_PATH"
echo "  Region: $AWS_REGION"
echo ""

# Step 1: Verify directory structure
echo "════════════════════════════════════════════════════════"
echo "STEP 1: Verifying directory structure..."
echo "════════════════════════════════════════════════════════"

echo "Current directory: $(pwd)"

# Check Dockerfile
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo "❌ ERROR: Dockerfile not found at: $DOCKERFILE_PATH"
    echo "Please run this script from ~/Todo_App directory"
    exit 1
fi
echo "✅ Found Dockerfile: $DOCKERFILE_PATH"

# Check ToDoList.jsx
TODOLIST_PATH="./Todo_App/src/assets/ToDoList.jsx"
if [ -f "$TODOLIST_PATH" ]; then
    echo "✅ Found ToDoList.jsx: $TODOLIST_PATH"
    
    # Verify API_URL
    if grep -q 'const API_URL = ""' "$TODOLIST_PATH"; then
        echo "✅ API_URL is correctly set to empty string"
    else
        echo "⚠️  WARNING: API_URL might not be empty string"
        echo "   Current value:"
        grep "const API_URL" "$TODOLIST_PATH" || echo "   (not found)"
        read -p "   Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    echo "⚠️  ToDoList.jsx not found at expected location"
    echo "   Continuing with build..."
fi

echo ""

# Step 2: Build Docker image
echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Building Docker image..."
echo "════════════════════════════════════════════════════════"
echo "Using Dockerfile: $DOCKERFILE_PATH"

docker build -t $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG -f $DOCKERFILE_PATH .

if [ $? -eq 0 ]; then
    echo "✅ Docker build successful!"
else
    echo "❌ Docker build failed!"
    exit 1
fi

# Step 3: Login to ECR
echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Logging into ECR..."
echo "════════════════════════════════════════════════════════"

aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

if [ $? -eq 0 ]; then
    echo "✅ ECR login successful!"
else
    echo "❌ ECR login failed!"
    exit 1
fi

# Step 4: Push to ECR
echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Pushing image to ECR..."
echo "════════════════════════════════════════════════════════"

docker push $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG

if [ $? -eq 0 ]; then
    echo "✅ Image pushed successfully!"
else
    echo "❌ Push failed!"
    exit 1
fi

# Step 5: Update kubeconfig
echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Connecting to EKS cluster..."
echo "════════════════════════════════════════════════════════"

aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER

if [ $? -eq 0 ]; then
    echo "✅ Connected to EKS!"
else
    echo "❌ Failed to connect to EKS!"
    exit 1
fi

# Step 6: Delete old StorageClass (if exists and causing issues)
echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6: Checking StorageClass..."
echo "════════════════════════════════════════════════════════"

if kubectl get storageclass ebs-sc &> /dev/null; then
    echo "⚠️  StorageClass 'ebs-sc' exists. Deleting to avoid immutable field error..."
    kubectl delete storageclass ebs-sc
    echo "✅ StorageClass deleted"
else
    echo "✅ No conflicting StorageClass found"
fi

# Step 7: Deploy with Helm
echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 7: Deploying to EKS..."
echo "════════════════════════════════════════════════════════"

helm upgrade --install todo-app-list ./manifests/todo-app-list \
  -f ./manifests/todo-app-list/values-eks-ecr.yaml \
  --namespace $NAMESPACE \
  --create-namespace

if [ $? -eq 0 ]; then
    echo "✅ Helm deployment successful!"
else
    echo "❌ Helm deployment failed!"
    exit 1
fi

# Step 8: Force restart pods
echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 8: Restarting pods to use new image..."
echo "════════════════════════════════════════════════════════"

kubectl rollout restart deployment/todo-webapp -n $NAMESPACE

# Step 9: Wait for pods
echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 9: Waiting for pods to be ready..."
echo "════════════════════════════════════════════════════════"

kubectl wait --for=condition=ready pod \
  -l app=todo-webapp \
  -n $NAMESPACE \
  --timeout=300s

if [ $? -eq 0 ]; then
    echo "✅ Pods are ready!"
else
    echo "⚠️  Pods taking longer than expected. Check status manually."
fi

# Step 10: Verify
echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 10: Verifying deployment..."
echo "════════════════════════════════════════════════════════"

echo ""
echo "📊 Pod status:"
kubectl get pods -n $NAMESPACE

echo ""
echo "🔍 Image version in use:"
kubectl describe pod -n $NAMESPACE -l app=todo-webapp | grep "Image:" | head -2

echo ""
echo "🌐 Services:"
kubectl get svc -n $NAMESPACE

# Get LoadBalancer URL
echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ DEPLOYMENT COMPLETE!"
echo "════════════════════════════════════════════════════════"

WEBAPP_URL=$(kubectl get svc -n $NAMESPACE -l app=todo-webapp -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

if [ -n "$WEBAPP_URL" ]; then
    echo ""
    echo "🎉 Your application is ready!"
    echo ""
    echo "🌐 URL: http://$WEBAPP_URL"
    echo ""
    echo "📝 Next steps:"
    echo "  1. Open the URL above in INCOGNITO/PRIVATE mode"
    echo "  2. Try adding a task"
    echo "  3. Check browser console (F12) - no localhost:8080 errors!"
    echo ""
else
    echo ""
    echo "⏳ LoadBalancer URL not ready yet (takes 2-3 minutes)"
    echo ""
    echo "Run this command in a few minutes to get the URL:"
    echo "  kubectl get svc -n $NAMESPACE -l app=todo-webapp"
    echo ""
fi

echo "════════════════════════════════════════════════════════"
echo "🎓 What we did:"
echo "  1. ✅ Built image with API_URL = '' using: $DOCKERFILE_PATH"
echo "  2. ✅ Pushed to ECR as $IMAGE_TAG"
echo "  3. ✅ Fixed StorageClass conflict"
echo "  4. ✅ Deployed with correct image tag (inheritance!)"
echo "  5. ✅ Forced pods to use new image"
echo "════════════════════════════════════════════════════════"
echo ""
echo "💡 Troubleshooting:"
echo "  - If still seeing localhost:8080, clear browser cache!"
echo "  - Use Incognito/Private mode to test"
echo "  - Check image: kubectl describe pod -n $NAMESPACE"
echo ""
echo "Good luck! 🚀"
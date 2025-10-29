#!/bin/bash
# deploy-eks-ecr.sh - Deploy to EKS with ECR

CHART_PATH="../manifests/todo-app-list"
NAMESPACE="todo-app-list"
VALUES_FILE="values-eks-ecr.yaml"
CLUSTER_NAME="todolist"
REGION="eu-west-1"

echo "☸️  Setting up Kubernetes for EKS..."

# 1. Switch to EKS context
echo "🔄 Updating kubectl config for EKS..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# 2. ✅ NEW: Ensure OIDC provider exists
echo "🔐 Checking/Creating OIDC provider..."
eksctl utils associate-iam-oidc-provider \
  --cluster $CLUSTER_NAME \
  --region $REGION \
  --approve

# 3. ✅ NEW: Install EBS CSI Driver (if not already installed)
echo "💾 Installing EBS CSI Driver..."

# Check if EBS CSI addon already exists
if aws eks describe-addon \
    --cluster-name $CLUSTER_NAME \
    --region $REGION \
    --addon-name aws-ebs-csi-driver &> /dev/null; then
  echo "   ℹ️  EBS CSI Driver already installed, skipping..."
else
  echo "   📦 Creating IAM service account for EBS CSI..."
  eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --region $REGION \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve \
    --override-existing-serviceaccounts

  echo "   🚀 Installing EBS CSI addon..."
  AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  
  aws eks create-addon \
    --cluster-name $CLUSTER_NAME \
    --region $REGION \
    --addon-name aws-ebs-csi-driver \
    --service-account-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole
  
  echo "   ⏳ Waiting for EBS CSI to be ready..."
  sleep 30
fi

# 4. Ensure namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
  echo "🆕 Creating namespace $NAMESPACE with Helm labels/annotations..."
  kubectl create namespace "$NAMESPACE"
  kubectl label namespace "$NAMESPACE" app.kubernetes.io/managed-by=Helm --overwrite
  kubectl annotate namespace "$NAMESPACE" meta.helm.sh/release-name=todo-app-list --overwrite
  kubectl annotate namespace "$NAMESPACE" meta.helm.sh/release-namespace=todo-app-list --overwrite
fi

# 5. Deploy application
echo "🚀 Deploying application to EKS..."
helm upgrade --install todo-app-list "$CHART_PATH" \
  -f "$CHART_PATH/$VALUES_FILE" \
  --namespace "$NAMESPACE"

echo ""
echo "⏳ Waiting for pods to be ready (this may take a few minutes)..."
kubectl wait --for=condition=ready pod \
  --all \
  -n "$NAMESPACE" \
  --timeout=600s

echo ""
echo "📊 Deployment status:"
kubectl get pods -n "$NAMESPACE"

echo ""
echo "🌐 Services:"
kubectl get svc -n "$NAMESPACE"

# ✅ NEW: Show PVC status
echo ""
echo "💾 Storage (PVC) status:"
kubectl get pvc -n "$NAMESPACE"

echo ""
echo "🌐 Access URLs (LoadBalancers may take 2-3 minutes to provision):"

# Get WebApp LoadBalancer
WEBAPP_LB=$(kubectl get svc -n "$NAMESPACE" \
  -l app.kubernetes.io/component=webapp \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

if [ -n "$WEBAPP_LB" ]; then
    echo "  📱 WebApp: http://$WEBAPP_LB"
else
    echo "  ⏳ WebApp LoadBalancer provisioning... (check with: kubectl get svc -n $NAMESPACE)"
fi

# Get MongoExpress LoadBalancer
MONGO_EXPRESS_LB=$(kubectl get svc -n "$NAMESPACE" \
  -l app.kubernetes.io/component=mongoexpress \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

if [ -n "$MONGO_EXPRESS_LB" ]; then
    echo "  🗄️  Mongo Express: http://$MONGO_EXPRESS_LB"
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "💡 Tip: Run 'kubectl logs -f -n $NAMESPACE -l app.kubernetes.io/name=todo-app' to view logs"
echo "💡 Tip: Run 'helm uninstall todo-app-list -n $NAMESPACE' to remove the deployment"

#!/bin/bash
# deploy-eks-ecr.sh - Deploy application to EKS
# Run this AFTER setting up EKS cluster and EBS CSI Driver

CHART_PATH="../manifests/todo-app-list"
NAMESPACE="todo-app-list"
VALUES_FILE="values-eks-ecr.yaml"
CLUSTER_NAME="todolist"
REGION="eu-west-1"

# ============================================
# PREREQUISITES CHECK
# ============================================
echo "🔍 Checking prerequisites..."
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check if aws CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm not found. Please install: https://helm.sh/docs/intro/install/"
    exit 1
fi

echo "✅ All prerequisites installed"
echo ""

# ============================================
# STEP 1: Connect to EKS Cluster
# ============================================
echo "📋 STEP 1: Connect to EKS Cluster"
echo "─────────────────────────────────────────"
echo "Configuring kubectl to connect to your EKS cluster..."
echo ""

aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "✅ Connected to cluster: $CLUSTER_NAME"
echo ""

# ============================================
# STEP 2: Check EBS CSI Driver
# ============================================
echo "📋 STEP 2: Check EBS CSI Driver Status"
echo "─────────────────────────────────────────"
echo "EBS CSI Driver is required for persistent storage (MongoDB)."
echo ""

if kubectl get pods -n kube-system | grep -q ebs-csi; then
    echo "✅ EBS CSI Driver is already installed"
else
    echo "⚠️  EBS CSI Driver is NOT installed"
    echo ""
    echo "To install EBS CSI Driver, you need to:"
    echo "  1. Create OIDC provider for your cluster"
    echo "  2. Create IAM role with EBS CSI permissions"
    echo "  3. Install the EBS CSI addon"
    echo ""
    echo "📖 For detailed instructions, see: docs/setup-ebs-csi.md"
    echo ""
    read -p "Continue without EBS CSI? (MongoDB won't work) [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled. Please setup EBS CSI first."
        exit 1
    fi
fi
echo ""

# ============================================
# STEP 3: Create Namespace
# ============================================
echo "📋 STEP 3: Create Application Namespace"
echo "─────────────────────────────────────────"
echo "Creating namespace for our application..."
echo ""

if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "ℹ️  Namespace '$NAMESPACE' already exists"
else
    kubectl create namespace "$NAMESPACE"
    kubectl label namespace "$NAMESPACE" app.kubernetes.io/managed-by=Helm
    kubectl annotate namespace "$NAMESPACE" meta.helm.sh/release-name=todo-app-list
    kubectl annotate namespace "$NAMESPACE" meta.helm.sh/release-namespace=todo-app-list
    echo "✅ Namespace created: $NAMESPACE"
fi
echo ""

# ============================================
# STEP 4: Deploy Application
# ============================================
echo "📋 STEP 4: Deploy Application with Helm"
echo "─────────────────────────────────────────"
echo "Deploying TODO application to Kubernetes..."
echo ""

helm upgrade --install todo-app-list "$CHART_PATH" \
  -f "$CHART_PATH/$VALUES_FILE" \
  --namespace "$NAMESPACE" \
  --wait \
  --timeout 10m

echo "✅ Application deployed"
echo ""

# ============================================
# STEP 5: Check Deployment Status
# ============================================
echo "📋 STEP 5: Verify Deployment"
echo "─────────────────────────────────────────"
echo "Waiting for all pods to be ready..."
echo ""

kubectl wait --for=condition=ready pod \
  --all \
  -n "$NAMESPACE" \
  --timeout=600s || echo "⚠️ Some pods may still be starting"

echo ""
echo "📊 Pod Status:"
kubectl get pods -n "$NAMESPACE"

echo ""
echo "💾 Storage Status:"
kubectl get pvc -n "$NAMESPACE"

echo ""
echo "🌐 Services:"
kubectl get svc -n "$NAMESPACE"
echo ""

# ============================================
# STEP 6: Get Access URLs
# ============================================
echo "📋 STEP 6: Access Information"
echo "─────────────────────────────────────────"
echo ""

# Get LoadBalancer URLs
WEBAPP_LB=$(kubectl get svc -n "$NAMESPACE" \
  -l app.kubernetes.io/component=webapp \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

if [ -n "$WEBAPP_LB" ]; then
    echo "📱 TODO App: http://$WEBAPP_LB"
else
    echo "⏳ LoadBalancer provisioning (check with: kubectl get svc -n $NAMESPACE)"
fi

MONGO_EXPRESS_LB=$(kubectl get svc -n "$NAMESPACE" \
  -l app.kubernetes.io/component=mongoexpress \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

if [ -n "$MONGO_EXPRESS_LB" ]; then
    echo "🗄️  Mongo Express: http://$MONGO_EXPRESS_LB"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "  ✅ Deployment Complete!"
echo "═══════════════════════════════════════════"
echo ""
echo "📚 Next Steps:"
echo "  • View logs: kubectl logs -f -n $NAMESPACE deployment/webapp"
echo "  • Get pods: kubectl get pods -n $NAMESPACE"
echo "  • Delete app: helm uninstall todo-app-list -n $NAMESPACE"
echo ""
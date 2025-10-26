#!/bin/bash
# deploy-eks-ecr.sh - Deploy to EKS with ECR

CHART_PATH="../manifests/todo-app-list"
NAMESPACE="todo-app-list"
VALUES_FILE="values-eks-ecr.yaml"

echo "☸️  Setting up Kubernetes for EKS..."

# 1. Switch to EKS context
echo "🔄 Updating kubectl config for EKS..."
aws eks update-kubeconfig --region eu-west-1 --name todolist

# 2. Install EBS CSI Driver (one-time)
if ! kubectl get deployment ebs-csi-controller -n kube-system &> /dev/null; then
    echo "📦 Installing EBS CSI Driver..."
    kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"
    echo "✅ EBS CSI Driver installed"
else
    echo "✅ EBS CSI Driver already installed"
fi

# 3. Add Bitnami Helm repo
echo "📚 Adding Bitnami Helm repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
helm repo update

# 4. Download MongoDB dependency
echo "⬇️  Downloading MongoDB dependency..."
pushd "$CHART_PATH" > /dev/null
helm dependency update
popd > /dev/null

# 5. Deploy application
echo "🚀 Deploying application to EKS..."
helm install todo-app-list "$CHART_PATH" -f "$CHART_PATH/$VALUES_FILE"

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

echo ""
echo "🌍 Access URLs (LoadBalancers may take 2-3 minutes to provision):"

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
echo "💡 Tip: Run 'helm uninstall todo-app-list' to remove the deployment"
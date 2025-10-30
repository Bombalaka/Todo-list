#!/bin/bash
# deploy-k8s-docker.sh - Simple deploy to Docker Desktop

CHART_PATH="../manifests/todo-app-list"
VALUES_FILE="values-docker-desktop.yaml"
NAMESPACE="todo-app-list"

echo "🚀 Deploying to Docker Desktop"
echo ""

# If namespace exists, clean it up first
if kubectl get namespace $NAMESPACE &>/dev/null; then
    echo "⚠️  Namespace exists. Cleaning up..."
    helm uninstall todo-app-list -n $NAMESPACE 2>/dev/null || true
    kubectl delete namespace $NAMESPACE
    
    echo "⏳ Waiting for cleanup..."
    while kubectl get namespace $NAMESPACE &>/dev/null; do
        sleep 2
    done
    echo "✅ Cleaned up"
    echo ""
fi

# Deploy
echo "🚀 Installing..."
helm upgrade --install todo-app-list "$CHART_PATH" \
  -f "$CHART_PATH/$VALUES_FILE" \
  --namespace $NAMESPACE \
  --create-namespace

if [ $? -ne 0 ]; then
    echo "❌ Failed!"
    exit 1
fi

echo "✅ Installed"
echo ""

# Wait for pods
echo "⏳ Waiting for pods to start..."
sleep 10

kubectl get pods -n $NAMESPACE
echo ""

# Wait for ready
echo "⏳ Waiting for ready..."
kubectl wait --for=condition=ready pod/mongodb-0 -n $NAMESPACE --timeout=120s 2>/dev/null && echo "✅ MongoDB ready"
kubectl wait --for=condition=ready pod -l app=todo-webapp -n $NAMESPACE --timeout=120s 2>/dev/null && echo "✅ Webapp ready"

echo ""
echo "📋 Status:"
kubectl get pods -n $NAMESPACE
echo ""

# Show URLs
WEBAPP_PORT=$(kubectl get svc todo-webapp-service -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
MONGO_PORT=$(kubectl get svc mongo-express-service -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)

echo "🌐 Access:"
echo "  WebApp:        http://localhost:${WEBAPP_PORT}"
echo "  Mongo Express: http://localhost:${MONGO_PORT}"
echo ""
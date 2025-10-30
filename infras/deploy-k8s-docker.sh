#! /bin/bash
# A script to deploy a Kubernetes application using docker desktop

# Variables
CHART_PATH="../manifests/todo-app-list"
VALUES_FILE="values-docker-desktop.yaml"
NAMESPACE="todo-app-list" 

echo "Installing Chart..."
helm install todo-app-list "$CHART_PATH" -f "$CHART_PATH/$VALUES_FILE" --namespace "$NAMESPACE" --create-namespace

echo "Show list of Helm releases..."
helm list -n "$NAMESPACE"

echo "Getting all pods..."
kubectl get pods -n "$NAMESPACE"

echo "Getting all services..."
kubectl get svc -n "$NAMESPACE"

echo "Waiting for the application to be ready..."
kubectl wait --for=condition=ready pod -l app=todo-webapp -n "$NAMESPACE" --timeout=60s
echo "Waiting for mongodb to be available..."
kubectl wait --for=condition=ready pod -l app=mongodb -n "$NAMESPACE" --timeout=120s


# Get WebApp NodePort
WEBAPP_PORT=$(kubectl get svc -n "$NAMESPACE" \
  -l app.kubernetes.io/component=webapp \
  -o jsonpath='{.items[0].spec.ports[0].nodePort}' 2>/dev/null)

if [ -n "$WEBAPP_PORT" ]; then
    echo "  📱 WebApp: http://localhost:$WEBAPP_PORT"
fi

# Get MongoExpress NodePort
MONGO_EXPRESS_PORT=$(kubectl get svc -n "$NAMESPACE" \
  -l app.kubernetes.io/component=mongoexpress \
  -o jsonpath='{.items[0].spec.ports[0].nodePort}' 2>/dev/null)

if [ -n "$MONGO_EXPRESS_PORT" ]; then
    echo "  🗄️  Mongo Express: http://localhost:$MONGO_EXPRESS_PORT"
fi
echo ""
echo "💡 Tip: Run 'kubectl logs -f -n todo-app-list -l app.kubernetes.io/name=todo-app' to view logs"
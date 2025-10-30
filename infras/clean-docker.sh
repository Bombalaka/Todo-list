#!/bin/bash
# force-cleanup.sh - Nuclear cleanup

NAMESPACE="todo-app-list"

echo "🗑️  FORCE CLEANUP"
echo ""

# Uninstall helm (all possible locations)
helm uninstall todo-app-list -n $NAMESPACE 2>/dev/null || true
helm uninstall todo-app-list -n default 2>/dev/null || true
helm uninstall todo-app-list 2>/dev/null || true

# Delete all resources
kubectl delete all --all -n $NAMESPACE 2>/dev/null || true
kubectl delete pvc --all -n $NAMESPACE 2>/dev/null || true
kubectl delete configmap --all -n $NAMESPACE 2>/dev/null || true
kubectl delete secret --all -n $NAMESPACE 2>/dev/null || true

# Delete namespace
kubectl delete namespace $NAMESPACE 2>/dev/null || true

echo "⏳ Waiting 30 seconds..."
sleep 30

# Check if still there
if kubectl get namespace $NAMESPACE &>/dev/null; then
    echo "❌ Namespace STILL exists!"
    kubectl get namespace $NAMESPACE
    exit 1
else
    echo "✅ Namespace fully deleted"
fi
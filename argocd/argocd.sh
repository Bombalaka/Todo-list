#!/bin/bash
# 🚀 ArgoCD Installation Script (Localhost Version)
# This script installs ArgoCD and accesses it via localhost (no LoadBalancer needed!)
# Created for: Yotaka K.
# Date: October 26, 2025

set -e  # Exit if any command fails

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables
NAMESPACE="argocd"
LOCAL_PORT=8080

# Helper functions
print_step() {
    echo -e "${CYAN}➡️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Welcome banner
clear
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}       ArgoCD Installation (Localhost Version)          ${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "This script will:"
echo "  1. Create ArgoCD namespace"
echo "  2. Install ArgoCD"
echo "  3. Wait for it to be ready"
echo "  4. Get your admin password"
echo "  5. Set up port-forwarding to localhost:$LOCAL_PORT"
echo ""
echo -e "${GREEN}✨ No LoadBalancer needed - saves money and is more secure!${NC}"
echo ""
read -p "Press Enter to start..."
echo ""

# Step 1: Check prerequisites
print_step "Checking kubectl connection..."
if ! kubectl cluster-info >/dev/null 2>&1; then
    print_error "Cannot connect to Kubernetes cluster!"
    echo "Please run: aws eks update-kubeconfig --region eu-west-1 --name todolist"
    exit 1
fi
print_success "Connected to cluster: $(kubectl config current-context)"
echo ""

# Step 2: Create namespace
print_step "Creating namespace '$NAMESPACE'..."

if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
    print_warning "Namespace '$NAMESPACE' already exists"
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Deleting existing namespace..."
        kubectl delete namespace $NAMESPACE
        echo "Waiting for namespace to be fully deleted..."
        sleep 10
        kubectl create namespace $NAMESPACE
        print_success "Namespace recreated"
    else
        print_info "Using existing namespace"
    fi
else
    kubectl create namespace $NAMESPACE
    print_success "Namespace created"
fi
echo ""

# Step 3: Install ArgoCD
print_step "Installing ArgoCD in namespace '$NAMESPACE'..."
print_info "This downloads official ArgoCD manifests and applies them"
echo ""

kubectl apply -n $NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

print_success "ArgoCD manifests applied"
echo ""

# Step 4: Wait for pods to be ready
print_step "Waiting for ArgoCD pods to be ready..."
print_info "This may take 2-3 minutes (downloading images, starting containers, etc.)"
echo ""

# Show the pods being created
kubectl get pods -n $NAMESPACE

echo ""
print_step "Waiting for all pods to be ready..."

# Wait for all pods with timeout
if kubectl wait --for=condition=ready pod --all -n $NAMESPACE --timeout=300s; then
    print_success "All ArgoCD pods are ready!"
else
    print_warning "Some pods might still be starting..."
    echo ""
    echo "Current status:"
    kubectl get pods -n $NAMESPACE
    echo ""
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo ""

# Step 5: Get admin password
print_step "Getting ArgoCD admin password..."

# Check if secret exists
if kubectl get secret argocd-initial-admin-secret -n $NAMESPACE >/dev/null 2>&1; then
    ARGOCD_PASSWORD=$(kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    print_success "Admin password retrieved"
else
    print_error "Could not find admin password secret!"
    echo "The secret 'argocd-initial-admin-secret' does not exist yet."
    echo "This is normal if ArgoCD just started. Wait a minute and try again."
    exit 1
fi
echo ""

# Step 6: Save credentials to file
CREDENTIALS_FILE="argocd-credentials.txt"
cat > $CREDENTIALS_FILE <<EOF
═══════════════════════════════════════════════════════
        ArgoCD Login Credentials (Localhost)
═══════════════════════════════════════════════════════

Date: $(date)

URL:      http://localhost:$LOCAL_PORT
Username: admin
Password: $ARGOCD_PASSWORD

═══════════════════════════════════════════════════════
                  HOW TO ACCESS
═══════════════════════════════════════════════════════

1. Keep this terminal window open (port-forward will run here)
2. Open a new terminal window or tab
3. Open your browser and go to: http://localhost:$LOCAL_PORT
4. Login with username 'admin' and the password above
5. Start using ArgoCD! ✨

═══════════════════════════════════════════════════════
                IMPORTANT NOTES
═══════════════════════════════════════════════════════

⚠️  Port-forward must stay running!
   - Don't close this terminal
   - If you close it, run: kubectl port-forward svc/argocd-server -n argocd 8080:443

⚠️  To stop ArgoCD access:
   - Press Ctrl+C in this terminal
   - ArgoCD is still running in the cluster, just not accessible

⚠️  To fully remove ArgoCD:
   - kubectl delete namespace argocd

═══════════════════════════════════════════════════════
                 USEFUL COMMANDS
═══════════════════════════════════════════════════════

# View ArgoCD pods
kubectl get pods -n argocd

# View ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# Get password again
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Restart port-forward (if stopped)
kubectl port-forward svc/argocd-server -n argocd 8080:443

═══════════════════════════════════════════════════════
EOF

print_success "Credentials saved to: $CREDENTIALS_FILE"
echo ""

# Step 7: Display summary
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              🎉 INSTALLATION COMPLETE! 🎉                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📋 Login Information:${NC}"
echo ""
echo -e "   URL:      ${GREEN}http://localhost:$LOCAL_PORT${NC}"
echo -e "   Username: ${GREEN}admin${NC}"
echo -e "   Password: ${GREEN}$ARGOCD_PASSWORD${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Save this password! ⚠️${NC}"
echo ""
echo -e "${CYAN}📁 Credentials also saved to: ${GREEN}$CREDENTIALS_FILE${NC}"
echo ""

# Step 8: Start port-forwarding
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}         Starting Port-Forward to localhost:$LOCAL_PORT        ${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""
print_info "How port-forwarding works:"
echo "  • Kubernetes listens on port 443 (HTTPS)"
echo "  • We forward it to your localhost:$LOCAL_PORT"
echo "  • You access ArgoCD at http://localhost:$LOCAL_PORT"
echo ""
print_warning "Keep this terminal open!"
echo "  • If you close it, port-forward stops"
echo "  • ArgoCD will still run in cluster, just not accessible"
echo ""
print_info "To access ArgoCD:"
echo "  1. Open a NEW terminal (leave this one running)"
echo "  2. Open browser: http://localhost:$LOCAL_PORT"
echo "  3. Login with admin / $ARGOCD_PASSWORD"
echo ""
print_info "To stop port-forward:"
echo "  • Press Ctrl+C in this terminal"
echo ""
read -p "Press Enter to start port-forward..."
echo ""
echo -e "${GREEN}✨ Port-forward is now active! ✨${NC}"
echo -e "${GREEN}🌐 Open your browser: http://localhost:$LOCAL_PORT${NC}"
echo ""
echo -e "${YELLOW}(Press Ctrl+C to stop)${NC}"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""

# Start port-forward (this will run until Ctrl+C)
kubectl port-forward svc/argocd-server -n $NAMESPACE $LOCAL_PORT:443
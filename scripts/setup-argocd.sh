#!/bin/bash
set -e

echo "Setting up Argo CD..."

# Create argocd namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install Argo CD
echo "Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
echo "Waiting for Argo CD to be ready..."
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=120s

# Get initial password
echo ""
echo "Argo CD Setup Complete!"
echo "========================================"
echo ""
echo "Access Argo CD UI:"
echo "1. Run: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "2. Open: https://localhost:8080"
echo ""
echo "Login credentials:"
echo "  Username: admin"
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "  Password: $PASSWORD"
echo ""
echo "To apply applications:"
echo "  kubectl apply -f argocd/dev-app.yaml"
echo "  kubectl apply -f argocd/staging-app.yaml"
echo "  kubectl apply -f argocd/prod-app.yaml"

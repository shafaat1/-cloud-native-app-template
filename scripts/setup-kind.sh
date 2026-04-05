#!/bin/bash
set -e

echo "Setting up Kind cluster for local development..."

# Create Kind cluster
kind create cluster --config scripts/kind-config.yaml

# Set context
kubectl cluster-info --context kind-dev-cluster

# Install Ingress Controller (NGINX)
echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Install cert-manager
echo "Installing Cert-Manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=120s

# Create self-signed issuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
EOF

echo "Kind cluster setup complete!"
echo "Cluster: kind-dev-cluster"
echo ""
echo "To use the cluster, run:"
echo "export KUBECONFIG=\$(kind get kubeconfig-path --name dev-cluster)"

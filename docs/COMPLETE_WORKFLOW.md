# Complete Cloud-Native Deployment Workflow

This guide walks through the complete workflow: local execution → Docker → Kubernetes (Kind/Minikube) → Helm → Argo CD.

---

## **Step 1: ✅ Execute App Locally**

Your app is now running and listening on `http://localhost:3000`.

**Endpoints:**
- `GET /` - Main endpoint returns "Hello, World! This is a cloud-native application."
- `GET /health` - Health check endpoint (returns `{"status": "healthy"}`)
- `GET /ready` - Readiness probe endpoint (returns `{"ready": true}`)
- `GET /metrics` - Prometheus metrics endpoint

**To run locally:**
```bash
npm install
npm start
```

**Test the app:**
```bash
curl http://localhost:3000
curl http://localhost:3000/health
curl http://localhost:3000/ready
```

---

## **Step 2: 🐳 Dockerize the App**

The `Dockerfile` has been updated with best practices:
- Multi-stage build for optimal image size
- Non-root user (appuser) for security
- Alpine Linux for minimal footprint
- Health check built-in
- Environment variable support

### **Build the Docker Image:**

Make sure Docker Desktop is running first.

```bash
# Build the image
docker build -t sample-app:1.0.0 . --no-cache

# Verify the image was created
docker images | grep sample-app

# Run the container locally
docker run -d \
  --name sample-app-local \
  -p 3000:3000 \
  sample-app:1.0.0

# Test the container
curl http://localhost:3000
curl http://localhost:3000/health

# View logs
docker logs sample-app-local

# Stop the container
docker stop sample-app-local
docker rm sample-app-local
```

### **Push to Docker Registry (Optional):**

```bash
# Tag with your registry
docker tag sample-app:1.0.0 <YOUR_DOCKER_USERNAME>/sample-app:1.0.0

# Login to Docker Hub
docker login

# Push to registry
docker push <YOUR_DOCKER_USERNAME>/sample-app:1.0.0
```

---

## **Step 3: 🎯 Setup Local Kubernetes Cluster**

### **Option A: Using Kind (Recommended)**

Kind is simpler and faster for local development.

```bash
# Create Kind cluster with our config
kind create cluster --config scripts/kind-config.yaml

# Verify cluster
kubectl cluster-info
kubectl get nodes

# Set context
kubectl config use-context kind-dev-cluster
```

### **Option B: Using Minikube**

```bash
# Start Minikube
minikube start --cpus=4 --memory=8192

# Get Minikube status
minikube status

# Set context
kubectl config use-context minikube
```

### **Install Ingress Controller (Kind only)**

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for Ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

---

## **Step 4: 📦 Deploy Using Helm**

### **Verify Helm is installed:**

```bash
helm version
helm repo list
```

### **Option A: Deploy using local Docker image**

First, load the image into Kind cluster:

```bash
# Load image into Kind
kind load docker-image sample-app:1.0.0 --name dev-cluster

# Deploy with Helm
helm upgrade --install sample-app helm/sample-app \
  -f environments/dev/values.yaml \
  --set image.repository=sample-app \
  --set image.tag=1.0.0 \
  --set image.pullPolicy=IfNotPresent \
  -n sample-app-dev \
  --create-namespace
```

### **Option B: Deploy using registry image**

```bash
# Deploy with Helm (uses registry image)
helm upgrade --install sample-app helm/sample-app \
  -f environments/dev/values.yaml \
  --set image.repository=<YOUR_DOCKER_USERNAME>/sample-app \
  --set image.tag=1.0.0 \
  -n sample-app-dev \
  --create-namespace
```

### **Verify Helm Deployment:**

```bash
# Check Helm release
helm list -n sample-app-dev

# Get deployment status
kubectl get deployments -n sample-app-dev
kubectl get pods -n sample-app-dev

# Port forward to access
kubectl port-forward svc/sample-app 3000:80 -n sample-app-dev

# Test in another terminal
curl http://localhost:3000
curl http://localhost:3000/health
```

### **Helm Commands Cheat Sheet:**

```bash
# Lint the chart
helm lint helm/sample-app

# Validate templates
helm template sample-app helm/sample-app -f environments/dev/values.yaml

# Dry-run (shows what will be deployed)
helm install sample-app helm/sample-app \
  -f environments/dev/values.yaml \
  --dry-run --debug

# Upgrade existing release
helm upgrade sample-app helm/sample-app -f environments/dev/values.yaml

# Rollback to previous version
helm rollback sample-app -n sample-app-dev

# View release history
helm history sample-app -n sample-app-dev

# Delete release
helm uninstall sample-app -n sample-app-dev
```

---

## **Step 5: 🚀 Deploy Using Argo CD**

### **1. Install Argo CD:**

```bash
# Create namespace
kubectl create namespace argocd

# Install Argo CD
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=120s
```

### **2. Access Argo CD UI:**

```bash
# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Open browser: https://localhost:8080
# Login: admin / <password from above>
```

### **3. Configure Git Repository:**

First, make sure the repository is public or Argo CD has credentials.

In Argo CD UI:
- Settings → Repositories → Connect Repo
- Repository URL: `https://github.com/shafaat1/-cloud-native-app-template.git`
- Connection method: HTTPS (unless using SSH)

### **4. Deploy Applications:**

```bash
# Apply Argo CD application manifests
kubectl apply -f argocd/dev-app.yaml
kubectl apply -f argocd/staging-app.yaml
kubectl apply -f argocd/prod-app.yaml

# Monitor applications
kubectl get applications -n argocd

# Watch application status
kubectl get applications -n argocd -w

# Check detailed status
kubectl describe application sample-app-dev -n argocd
```

### **5. Verify Deployment:**

```bash
# Check if namespaces were created
kubectl get namespaces | grep sample-app

# Check pods
kubectl get pods -n sample-app-dev
kubectl get pods -n sample-app-staging
kubectl get pods -n sample-app-prod

# Port forward to test
kubectl port-forward svc/sample-app 3000:80 -n sample-app-dev

# In another terminal
curl http://localhost:3000
```

### **Argo CD Commands Cheat Sheet:**

```bash
# Get application status
kubectl get application sample-app-dev -n argocd -o yaml

# Force sync
kubectl patch application sample-app-dev -n argocd \
  -p '{"metadata":{"finalizers":null}}' --type merge

# Check Argo CD server logs
kubectl logs -f deployment/argocd-server -n argocd

# Get all applications
kubectl get applications -n argocd

# Delete application
kubectl delete application sample-app-dev -n argocd
```

---

## **Summary of All Commands (Quick Reference)**

### **Local Development:**
```bash
npm install
npm start
```

### **Docker:**
```bash
docker build -t sample-app:1.0.0 .
docker run -d -p 3000:3000 sample-app:1.0.0
```

### **Kubernetes Cluster:**
```bash
kind create cluster --config scripts/kind-config.yaml
kubectl cluster-info
```

### **Helm Deployment:**
```bash
helm upgrade --install sample-app helm/sample-app \
  -f environments/dev/values.yaml \
  -n sample-app-dev --create-namespace
```

### **Argo CD Deployment:**
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/dev-app.yaml
```

---

## **Troubleshooting**

### **Docker Issues:**
- Ensure Docker Desktop is running
- Check: `docker ps`
- Restart Docker: `docker restart`

### **Kubernetes Issues:**
- Check cluster: `kubectl cluster-info`
- Check nodes: `kubectl get nodes`
- Check pods: `kubectl get pods --all-namespaces`

### **Helm Issues:**
- Lint chart: `helm lint helm/sample-app`
- Validate: `helm template sample-app helm/sample-app`
- Check release: `helm list -n sample-app-dev`

### **Argo CD Issues:**
- Check status: `kubectl get applications -n argocd`
- View logs: `kubectl logs -f deployment/argocd-server -n argocd`
- Check sync: `kubectl describe application sample-app-dev -n argocd`

---

## **Next Steps**

1. Start Docker Desktop
2. Build the Docker image
3. Create a Kind cluster
4. Deploy with Helm
5. Install and use Argo CD for GitOps deployments

All files are in place and ready to use!

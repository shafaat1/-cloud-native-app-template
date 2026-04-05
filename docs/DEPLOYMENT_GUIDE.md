# Deployment Guide

This guide covers deploying the Sample App to Kubernetes clusters using Helm and Argo CD.

## Prerequisites

- Kubernetes cluster (1.20+)
- Helm 3.x
- kubectl configured to access your cluster
- Docker registry credentials (if using private registry)

## Quick Start

### 1. Add the Helm Repository

```bash
# For local deployment
helm repo add local . --force-update
helm repo update
```

### 2. Deploy to Development

```bash
helm upgrade --install sample-app helm/sample-app \
  -f environments/dev/values.yaml \
  -n sample-app-dev \
  --create-namespace
```

### 3. Deploy to Staging

```bash
helm upgrade --install sample-app helm/sample-app \
  -f environments/staging/values.yaml \
  -n sample-app-staging \
  --create-namespace
```

### 4. Deploy to Production

```bash
helm upgrade --install sample-app helm/sample-app \
  -f environments/prod/values.yaml \
  -n sample-app-prod \
  --create-namespace
```

## Verifying Deployment

```bash
# Check deployment status
kubectl get deployments -n sample-app-dev
kubectl get pods -n sample-app-dev
kubectl logs -f deployment/sample-app -n sample-app-dev

# Port forward to access the app
kubectl port-forward svc/sample-app 3000:80 -n sample-app-dev
# Access at http://localhost:3000
```

## GitOps Deployment with Argo CD

### 1. Install Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Deploy Applications

```bash
# Create Application resources
kubectl apply -f argocd/dev-app.yaml
kubectl apply -f argocd/staging-app.yaml
kubectl apply -f argocd/prod-app.yaml

# Monitor sync status
kubectl get applications -n argocd
```

### 3. Access Argo CD UI

```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Open https://localhost:8080 and login with:
- Username: `admin`
- Password: (from above command)

## Updating Values

### Using --values flag

```bash
helm upgrade sample-app helm/sample-app \
  -f environments/prod/values.yaml \
  --set image.tag=v1.2.3 \
  -n sample-app-prod
```

### Updating individual values

```bash
helm upgrade sample-app helm/sample-app \
  --reuse-values \
  --set replicaCount=5 \
  -n sample-app-prod
```

## Rolling Back

```bash
# View release history
helm history sample-app -n sample-app-prod

# Rollback to previous release
helm rollback sample-app -n sample-app-prod

# Rollback to specific revision
helm rollback sample-app 2 -n sample-app-prod
```

## Troubleshooting

### Check deployment status
```bash
kubectl describe deployment sample-app -n sample-app-dev
```

### View logs
```bash
kubectl logs -f deployment/sample-app -n sample-app-dev
```

### Debug pod
```bash
kubectl exec -it <pod-name> -n sample-app-dev -- /bin/bash
```

### Helm validation
```bash
helm lint helm/sample-app
helm template sample-app helm/sample-app -f environments/dev/values.yaml
```

### Argo CD troubleshooting
```bash
# Check application status
kubectl describe application sample-app-dev -n argocd

# View Argo CD logs
kubectl logs -f deployment/argocd-server -n argocd
```

## Resource Cleanup

### Delete Helm release
```bash
helm uninstall sample-app -n sample-app-dev
```

### Delete namespace
```bash
kubectl delete namespace sample-app-dev
```

### Delete Argo CD application
```bash
kubectl delete application sample-app-dev -n argocd
```

## Best Practices

1. **Always test deployments in dev environment first**
2. **Use namespace for environment isolation**
3. **Set resource limits and requests**
4. **Configure health checks (liveness and readiness probes)**
5. **Use autoscaling for production workloads**
6. **Enable Pod Disruption Budgets for high availability**
7. **Keep Helm values organized by environment**
8. **Review all changes in pull requests before merging**
9. **Use GitOps for production deployments (Argo CD)**
10. **Monitor and log all deployments**

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

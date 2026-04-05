# Cloud Native App Template

A production-ready, cloud-native application template featuring:
- **Containerized App**: Docker containerization with security best practices
- **Kubernetes Ready**: Helm charts for multi-environment deployment
- **GitOps**: Argo CD integration for declarative deployments
- **Local Development**: Kind (Kubernetes in Docker) setup included
- **CI/CD**: GitHub Actions workflows for automated builds and deployments
- **Scalability**: Horizontal Pod Autoscaler configuration
- **High Availability**: Pod Disruption Budgets and multiple replicas

## Quick Start

### Prerequisites
- Docker
- kubectl
- Helm 3+
- Kind (for local development)
- Node.js 18+

### Local Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Run tests
npm test
```

### Local Kubernetes Cluster

```bash
# Setup Kind cluster
make kind-setup

# Deploy with Helm
make helm-deploy

# Setup ArgoCD
make argocd-setup

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Login: admin / <password from secret>
```

## Project Structure

```
.
├── app/                          # Application source code
│   └── index.js
├── Dockerfile                    # Container image definition
├── helm/                         # Helm charts for Kubernetes
│   └── sample-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── environments/                 # Environment-specific configurations
│   ├── dev/
│   ├── staging/
│   └── prod/
├── argocd/                       # Argo CD application manifests
├── .github/workflows/            # GitHub Actions CI/CD
├── scripts/                      # Setup and automation scripts
└── docs/                         # Documentation
```

## Deployment

### Development Environment
```bash
helm upgrade --install sample-app helm/sample-app -f environments/dev/values.yaml
```

### Staging Environment
```bash
helm upgrade --install sample-app helm/sample-app -f environments/staging/values.yaml
```

### Production Environment
```bash
helm upgrade --install sample-app helm/sample-app -f environments/prod/values.yaml
```

## GitOps with Argo CD

Deploy using declarative GitOps:

```bash
kubectl apply -f argocd/dev-app.yaml
kubectl apply -f argocd/staging-app.yaml
kubectl apply -f argocd/prod-app.yaml
```

## CI/CD Pipeline

### Build and Push
- Triggered on push to main
- Builds Docker image
- Pushes to registry
- Updates Helm values

### Helm Testing
- Validates chart syntax
- Tests template rendering
- Runs on pull requests

## Monitoring & Observability

Includes configurations for:
- Prometheus metrics collection
- Liveness and readiness probes
- Resource requests and limits
- Horizontal Pod Autoscaling (HPA)

## Security Practices

- Non-root container user
- Read-only root filesystem
- Resource limits enforced
- Network policies (can be added)
- RBAC configurations

## Documentation

- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)
- [GitOps Best Practices](docs/GITOPS_BEST_PRACTICES.md)

## License

MIT

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Support

For issues and questions, please open an issue on GitHub.

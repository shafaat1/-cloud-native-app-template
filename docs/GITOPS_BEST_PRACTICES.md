# GitOps Best Practices

## Core Principles

### 1. Declarative Infrastructure

All infrastructure should be declared in Git, not created manually.

```yaml
# ✅ Good - Declarative
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
spec:
  replicas: 3

# ❌ Bad - Imperative
kubectl scale deployment sample-app --replicas=3
```

### 2. Git as Single Source of Truth

- All changes go through Git
- No manual kubectl apply
- Code review before deployment

### 3. Automated Synchronization

Argo CD automatically keeps cluster state matching Git:

```yaml
syncPolicy:
  automated:
    prune: true      # Remove resources not in Git
    selfHeal: true   # Revert manual changes
```

### 4. Observability

Monitor sync status and alert on failures:

```bash
kubectl get application -w
```

## Environment Promotion

```
Code Change → DEV (auto) → STAGING (manual) → PROD (manual)
```

### Promotion Steps

1. **Dev** - Automatic via GitHub Actions
   - Build Docker image
   - Push to registry
   - Update image tag in Git

2. **Staging** - Manual promotion
   - Edit `environments/staging/values.yaml`
   - Commit and push
   - Argo CD auto-syncs

3. **Production** - Manual promotion
   - Edit `environments/prod/values.yaml`
   - Code review required
   - Argo CD auto-syncs

## Secrets Management

Never commit secrets to Git. Use one of:

1. **Sealed Secrets**
   ```bash
   kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml
   ```

2. **External Secrets Operator**
   ```yaml
   apiVersion: external-secrets.io/v1beta1
   kind: ExternalSecret
   ```

3. **Argo CD Repository Credentials**
   ```bash
   kubectl create secret generic private-repo -n argocd
   ```

## Image Tag Strategy

- **Dev**: `latest`
- **Staging**: Specific version (e.g., `v1.0.0`)
- **Prod**: Pinned version (e.g., `v1.0.0`)

## Rollback Strategy

### Git-based Rollback

```bash
# Revert the problematic commit
git revert <commit-hash>
git push

# Argo CD will automatically sync
```

### Manual Rollback

```bash
kubectl rollout undo deployment/sample-app -n sample-app-prod
```

## Common Patterns

### Blue-Green Deployments

```yaml
# Switch traffic between two versions
apiVersion: v1
kind: Service
metadata:
  name: sample-app
spec:
  selector:
    version: blue  # or green
```

### Canary Deployments

Use Flagger or Argo Rollouts for gradual traffic shift.

### Progressive Delivery

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: sample-app
spec:
  strategy:
    canary:
      steps:
        - setWeight: 20
        - pause: {duration: 5m}
```

## Monitoring and Alerting

Monitor these metrics:
- Deployment frequency
- Lead time for changes
- Change failure rate
- Mean time to recovery

## Team Workflows

1. Developer creates PR
2. CI validates (lint, test)
3. Team reviews
4. Merge to main
5. CI builds and pushes image
6. Argo CD automatically deploys

For production, require additional approval before merging.
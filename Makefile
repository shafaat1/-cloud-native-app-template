.PHONY: help build test deploy clean docker-build docker-push helm-lint helm-deploy kind-setup argocd-setup

help:
	@echo "Cloud Native App Template - Available Commands"
	@echo "============================================="
	@grep -E '^\.PHONY:|^[a-zA-Z_-]+:' Makefile | sed 's/\.PHONY: //' | sed 's/:$//'

# Local development
build:
	npm install
	npm run build

test:
	npm test

dev:
	npm run dev

# Docker
docker-build:
	docker build -t sample-app:latest .

docker-push:
	docker tag sample-app:latest $(DOCKER_REGISTRY)/sample-app:latest
	docker push $(DOCKER_REGISTRY)/sample-app:latest

# Helm
helm-lint:
	helm lint helm/sample-app

helm-test:
	helm template helm/sample-app

helm-deploy:
	helm upgrade --install sample-app helm/sample-app -f helm/sample-app/values.yaml

# Kind (local Kubernetes)
kind-setup:
	kind create cluster --config scripts/kind-config.yaml
	bash scripts/setup-kind.sh

kind-delete:
	kind delete cluster --name dev-cluster

# ArgoCD
argocd-setup:
	bash scripts/setup-argocd.sh

# Cleanup
clean:
	rm -rf node_modules dist build
	docker system prune -f

.PHONY: help build test dev docker-build docker-push helm-lint helm-test helm-deploy kind-setup kind-delete argocd-setup clean

# Kustomize Deployment Guide

This project uses **Kustomize** for managing Kubernetes manifests across different environments.

## 📁 Directory Structure

```
k8s/
├── base/                          # Base configurations (shared across all environments)
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── users-deployment.yaml
│   ├── users-service.yaml
│   ├── logout-deployment.yaml
│   ├── logout-service.yaml
│   └── mysql-configmap.yaml
│
└── overlays/                      # Environment-specific configurations
    ├── local/                     # Local development (Kind/Minikube)
    │   ├── kustomization.yaml
    │   ├── mysql-deployment.yaml
    │   ├── mysql-service.yaml
    │   ├── mysql-pvc.yaml
    │   ├── secrets.yaml
    │   └── ingress.yaml
    │
    ├── staging/                   # Staging environment (EKS with MySQL pod)
    │   ├── kustomization.yaml
    │   ├── mysql-deployment.yaml
    │   ├── mysql-service.yaml
    │   ├── mysql-pvc.yaml
    │   ├── secrets.yaml
    │   └── ingress.yaml
    │
    └── production/                # Production (EKS with RDS)
        ├── kustomization.yaml
        ├── ingress.yaml
        └── secrets-instructions.md
```

## 🚀 Quick Start

### Prerequisites

- `kubectl` installed and configured
- `kustomize` installed (or use `kubectl` with `-k` flag)
- Local Kubernetes cluster (for local deployment) or EKS access (for production)

### Install Kustomize (if not already installed)

```bash
# On Linux
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# On macOS
brew install kustomize

# Or use kubectl (v1.14+) with -k flag
```

## 📦 Deployment Options

### Option 1: Local Development

Deploy the application with a local MySQL database for development:

```bash
# Preview what will be applied (dry-run)
kubectl kustomize k8s/overlays/local

# Apply the configuration
kubectl apply -k k8s/overlays/local

# Or using kustomize directly
kustomize build k8s/overlays/local | kubectl apply -f -
```

**What gets deployed:**
- All base resources (frontend, users-service, logout-service)
- Local MySQL database with PVC (local-path storage)
- Development secrets (plaintext, NOT for production)
- Ingress configuration for local access
- Images from localhost:5000 registry

**Best for:** Local development on Minikube, Kind, or Docker Desktop

---

### Option 2: Staging Environment

Deploy to staging with MySQL pod on AWS EKS:

```bash
# Preview what will be applied
kubectl kustomize k8s/overlays/staging

# Apply the configuration
kubectl apply -k k8s/overlays/staging
```

**What gets deployed:**
- All base resources with staging tags from ECR
- MySQL database with AWS EBS PVC (gp2 storage class)
- 1 replica of each service
- Staging ingress with TLS (letsencrypt-staging)
- Resource limits on MySQL container

**Best for:** Testing on AWS before production, integration testing

---

### Staging

Secrets are included in `k8s/overlays/staging/secrets.yaml` but should be updated:

```bash
# Update staging secrets
kubectl create secret generic db-password \
  --from-literal=password=<strong-staging-password> \
  --dry-run=client -o yaml | kubectl apply -f -
```

Create ECR secret for pulling images:

```bash
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=301678011652.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  -n tms-app
```

### Option 3: Production (AWS/EKS)

Deploy to production using AWS ECR images and RDS database:

```bash
# FIRST: Create the necessary secrets (see instructions below)

# Preview what will be applied
kubectl kustomize k8s/overlays/production

# Apply the configuration
kubectl apply -k k8s/overlays/production
```

**What gets deployed:**
- All base resources with production images from ECR
- 2 replicas of each service (for high availability)
- Production ingress with TLS (letsencrypt-prod)
- No MySQL pod (uses external AWS RDS)

**Best for:** Production workloads with high availability

## 🔐 Managing Secrets

### Local Development

Secrets are included in `k8s/overlays/local/secrets.yaml` for convenience.

**⚠️ WARNING:** These are development-only secrets. Never use these in production!

### Production

Create secrets manually before deploying to production:

```bash
# Database endpoint (RDS)
kubectl create secret generic rds-endpoint \
  --from-literal=endpoint=<your-rds-endpoint> \
  -n tms-app

# Database credentials
kubectl create secret generic db-username \
  --from-literal=username=<your-db-username> \
  -n tms-app

kubectl create secret generic db-password \
  --from-literal=password=<your-db-password> \
  -n tms-app

kubectl create secret generic db-name \
  --from-literal=name=task_management \
  -n tms-app

# ECR registry credentials (for pulling images)
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=301678011652.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  -n tms-app
```

## 🔧 Customization

### Changing Image Tags

Edit the `images` section in the respective `kustomization.yaml`:

```yaml
# k8s/overlays/local/kustomization.yaml
images:
  - name: task-manager:frontend
    newName: localhost:5000/task-manager
    newTag: frontend-v2  # Change this
```

### Adjusting Replicas

Edit the `replicas` section in production:

```yaml
# k8s/overlays/production/kustomization.yaml
replicas:
  - name: frontend
    count: 3  # Increase replicas
```

### Adding Environment Variables

Create a patch in your overlay:

```yaml
patches:
  - patch: |-
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: frontend
      spec:
        template:
          spec:
            containers:
              - name: frontend
                env:
                  - name: NEW_VAR
                    value: "new-value"
    target:
      kind: Deployment
      name: frontend
```

## 📊 Common Commands

```bash
# View all resources that will be created
kubectl kustomize k8s/overlays/local

# Apply changes
kubectl apply -k k8s/overlays/local

# View differences before applying
kubectl diff -k k8s/overlays/local

# Delete all resources
kubectl delete -k k8s/overlays/local

# Watch deployment status
kubectl get pods -n tms-app -w

# Check service status
kubectl get svc -n tms-app

# View ingress
kubectEnvironment Comparison

| Feature | Local | Staging | Production |
|---------|-------|---------|------------|
| **Cluster** | Minikube/Kind/Docker Desktop | AWS EKS | AWS EKS |
| **Database** | MySQL Pod (local-path) | MySQL Pod (EBS gp2) | AWS RDS |
| **Replicas** | 1 | 1 | 2 |
| **Storage** | local-path (1Gi) | gp2 (5Gi) | RDS |
| **Images** | localhost:5000 | ECR (staging tags) | ECR (production tags) |
| **Ingress** | No TLS | TLS (staging cert) | TLS (prod cert) |
| **Secrets** | In-repo (dev only) | Must create manually | AWS Secrets Manager |
| **Resources** | No limits | Memory/CPU limits | Production limits |create a new environment (e.g., staging):

```bash
# Create directory
mkdir -p k8s/overlays/staging

# Create kustomization.yaml
cat > k8s/overlays/staging/kustomization.yaml << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: tms-app

resources:
  - ../../base

commonLabels:
  environment: staging

# Add your staging-specific configurations
EOF
```

## 📝 Benefits of This Structure

✅ **DRY Principle**: Base configurations are defined once and reused  
✅ **Environment Isolation**: Each overlay is independent  
Create separate applications for each environment:

```yaml
# Local/Dev Environment
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: task-manager-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-repo/task-manager
    targetRevision: main
    path: k8s/overlays/local
  destination:
    server: https://kubernetes.default.svc
    namespace: tms-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
---
# Staging Environment
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: task-manager-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-repo/task-manager
    targetRevision: staging
    path: k8s/overlays/staging
  destination:
    server: https://your-staging-cluster
    namespace: tms-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
---
# Production Environment
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: task-manager-production
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-repo/task-manager
    targetRevision: release
    path: k8s/overlays/production
  destination:
    server: https://your-production-cluster
    namespace: tms-app
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
    syncOptions:
      - CreateNamespace=ps://github.com/your-repo/task-manager
    targetRevision: HEAD
    path: k8s/overlays/local
  destination:
    server: https://kubernetes.default.svc
    namespace: tms-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### With GitHub Actions

```yaml
- name: Deploy to EKS
  run: |
    kubectl apply -k k8s/overlays/production
```

## 🐛 Troubleshooting

**Issue: Resources not applying**
```bash
# Check namespace exists
kubectl get namespace tms-app

# Verify kustomization builds
kustomize build k8s/overlays/local
```

**Issue: Image pull errors**
```bash
# Check if secret exists
kubectl get secret ecr-registry-secret -n tms-app

# Recreate ECR secret if expired
kubectl delete secret ecr-registry-secret -n tms-app
# Then recreate (see secrets section above)
```

**Issue: Service not accessible**
```bash
# Check ingress
kubectl describe ingress tms-ingress -n tms-app

# Check if ingress controller is running
kubectl get pods -n ingress-nginx
```

## 📚 Additional Resources

- [Kustomize Documentation](https://kustomize.io/)
- [Kubectl Book](https://kubectl.docs.kubernetes.io/)
- [Kubernetes Patterns](https://k8spatterns.io/)

---

**Need help?** Check the individual README files in each overlay directory for environment-specific instructions.

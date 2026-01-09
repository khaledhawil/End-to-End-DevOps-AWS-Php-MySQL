# Task Management System - Kubernetes with Kustomize

This directory contains Kubernetes manifests managed with **Kustomize** for deploying the Task Management System across different environments.

## 🎯 What is Kustomize?

Kustomize is a Kubernetes-native configuration management tool that allows you to customize YAML files without templating. It uses a declarative approach to manage environment-specific configurations.

## 📂 Structure

```
k8s/
├── base/              # Shared base configurations
├── overlays/          # Environment-specific overrides
│   ├── local/        # Local development setup
│   ├── staging/      # Staging environment
│   └── production/   # Production AWS/EKS setup
└── KUSTOMIZE_GUIDE.md  # Detailed usage guide
```

## 🚀 Quick Deploy

### Local Development
```bash
kubectl apply -k k8s/overlays/local
```

### Staging
```bash
kubectl apply -k k8s/overlays/staging
```

### Production (AWS/EKS)
```bash
# First, create required secrets (see KUSTOMIZE_GUIDE.md)
kubectl apply -k k8s/overlays/production
```

## 📖 Documentation

For complete instructions, see [KUSTOMIZE_GUIDE.md](./KUSTOMIZE_GUIDE.md)

## ⚡ Key Benefits

- **Single source of truth**: Base configurations shared across environments
- **Environment-specific overrides**: Easy to manage differences
- **GitOps ready**: Works with ArgoCD, Flux, etc.
- **No templating**: Pure Kubernetes YAML
- **Built into kubectl**: No additional tools required (kubectl >= 1.14)

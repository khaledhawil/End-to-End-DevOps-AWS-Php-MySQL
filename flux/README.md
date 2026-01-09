# Flux

This directory contains Flux CD configurations for GitOps continuous deployment.

## 📂 Structure

```
flux/
└── clusters/
    ├── local/          # Local development cluster
    ├── staging/        # Staging environment
    └── production/     # Production environment
```

Each cluster directory contains:
- `git-repository.yaml` - Defines the Git source
- `kustomization-app.yaml` - Defines what to deploy from the repo

## 🚀 Quick Start

1. **Install Flux CLI**
   ```bash
   ../install-flux.sh
   ```

2. **Bootstrap a cluster**
   ```bash
   ../flux-bootstrap.sh local --github-user YOUR_USER --github-token YOUR_TOKEN
   ```

3. **Monitor deployments**
   ```bash
   flux get kustomizations -w
   ```

## 📖 Documentation

- [Complete Flux Guide](../FLUX_GUIDE.md)
- [Quick Reference](../FLUX_QUICK_REF.md)
- [Official Flux Docs](https://fluxcd.io/flux/)

## 🔄 GitOps Workflow

1. Edit manifests in `k8s/overlays/{environment}/`
2. Commit and push to the appropriate branch
3. Flux automatically applies changes
4. Monitor with `flux get kustomizations -w`

## 🌍 Branch Strategy

- `main` → Local environment
- `staging` → Staging environment
- `release` → Production environment

# GitOps Deployment Overview

This project supports **two deployment methods**:

## 1️⃣ Kustomize (Manual/CI/CD)

Traditional kubectl apply with Kustomize overlays.

**Best for:**
- Quick manual deployments
- CI/CD pipelines (GitHub Actions, Jenkins, etc.)
- Learning Kubernetes
- Simple environments

**Usage:**
```bash
# Direct deployment
kubectl apply -k k8s/overlays/local

# Or use the script
./deploy-k8s.sh local apply
```

📖 **Documentation:** [k8s/KUSTOMIZE_GUIDE.md](k8s/KUSTOMIZE_GUIDE.md)

---

## 2️⃣ Flux CD (GitOps - Recommended)

Automated continuous deployment with Git as the source of truth.

**Best for:**
- Production environments
- Multi-environment management
- Automated deployments
- Teams collaborating on infrastructure
- Audit trails and rollback capability

**Features:**
- ✅ Automatic sync from Git
- ✅ Automatic rollback on failure
- ✅ Multi-tenancy support
- ✅ Image automation
- ✅ Notifications (Slack, Discord, etc.)
- ✅ Secret management integration
- ✅ Drift detection and correction

**Usage:**
```bash
# 1. Install Flux CLI
./install-flux.sh

# 2. Bootstrap your cluster
./flux-bootstrap.sh staging \
  --github-user YOUR_USER \
  --github-token YOUR_TOKEN

# 3. Make changes and push to Git
vim k8s/overlays/staging/mysql-deployment.yaml
git add . && git commit -m "Update MySQL" && git push

# 4. Flux automatically applies changes!
flux get kustomizations -w
```

📖 **Documentation:** [FLUX_GUIDE.md](FLUX_GUIDE.md)

---

## 🎯 Comparison

| Feature | Kustomize | Flux CD |
|---------|-----------|---------|
| **Deployment** | Manual kubectl | Automatic from Git |
| **Sync** | On-demand | Continuous (configurable) |
| **Rollback** | Manual | Automatic on failure |
| **Drift Detection** | No | Yes |
| **Multi-Environment** | Via scripts | Native support |
| **Audit Trail** | Git commits | Git + Kubernetes events |
| **Learning Curve** | Low | Medium |
| **Production Ready** | Yes | Yes |
| **Image Updates** | Manual | Can be automated |
| **Secrets** | Manual | Sealed Secrets/SOPS |
| **Notifications** | Via CI/CD | Built-in |

## 🚀 Quick Start Guide

### For Local Development (Kustomize)
```bash
kubectl apply -k k8s/overlays/local
```

### For Staging/Production (Flux - Recommended)
```bash
# Install
./install-flux.sh

# Bootstrap
./flux-bootstrap.sh staging --github-user USER --github-token TOKEN

# Monitor
flux get kustomizations -w
```

## 📂 Project Structure

```
.
├── k8s/                          # Kubernetes manifests
│   ├── base/                     # Base resources
│   └── overlays/                 # Environment-specific
│       ├── local/
│       ├── staging/
│       └── production/
│
├── flux/                         # Flux CD configs
│   └── clusters/                 # Per-cluster configs
│       ├── local/
│       ├── staging/
│       └── production/
│
├── deploy-k8s.sh                 # Kustomize deployment script
├── flux-bootstrap.sh             # Flux bootstrap script
├── install-flux.sh               # Flux CLI installer
│
├── KUSTOMIZE_GUIDE.md           # Kustomize documentation
├── KUSTOMIZE_QUICK_REF.md       # Kustomize quick reference
├── FLUX_GUIDE.md                # Flux documentation
└── FLUX_QUICK_REF.md            # Flux quick reference
```

## 🌍 Environment Strategy

| Environment | Branch | Kustomize | Flux |
|-------------|--------|-----------|------|
| **Local** | `main` | ✅ Recommended | Optional |
| **Staging** | `staging` | ✅ Supported | ⭐ Recommended |
| **Production** | `release` | ✅ Supported | ⭐⭐ Highly Recommended |

## 🔄 Recommended Workflow

### Development Flow
```bash
# Local: Use Kustomize for quick iterations
kubectl apply -k k8s/overlays/local

# Make changes, test locally
vim k8s/overlays/local/...
kubectl apply -k k8s/overlays/local
```

### Staging/Production Flow (GitOps)
```bash
# 1. Create feature branch
git checkout -b feature/update-mysql

# 2. Make changes
vim k8s/overlays/staging/mysql-deployment.yaml

# 3. Commit and push
git add k8s/overlays/staging/
git commit -m "feat: increase MySQL resources"
git push origin feature/update-mysql

# 4. Create PR to staging branch
# Review and merge

# 5. Flux automatically deploys to staging
flux get kustomizations -w

# 6. Test in staging
kubectl get pods -n tms-app

# 7. When ready, merge staging → release
# Flux automatically deploys to production
```

## 🔐 Secret Management

### Kustomize (Development)
```yaml
# Plain secrets in k8s/overlays/local/secrets.yaml
# ⚠️ Never commit production secrets!
```

### Flux (Staging/Production)
```bash
# Option 1: Sealed Secrets (Recommended)
kubeseal < secret.yaml > sealed-secret.yaml
git add sealed-secret.yaml  # Safe to commit!

# Option 2: SOPS (Mozilla)
sops --encrypt secret.yaml > secret.enc.yaml

# Option 3: External Secrets Operator
# Sync from AWS Secrets Manager, Azure Key Vault, etc.
```

## 📊 Monitoring

### Kustomize
```bash
kubectl get pods -n tms-app
kubectl logs -n tms-app -l app=frontend
```

### Flux
```bash
# Overall status
flux check

# Watch reconciliation
flux get kustomizations -w

# View logs
flux logs --all-namespaces --follow

# Application status
kubectl get pods -n tms-app
```

## 🆘 Getting Help

- **Kustomize Issues:** See [k8s/KUSTOMIZE_GUIDE.md](k8s/KUSTOMIZE_GUIDE.md)
- **Flux Issues:** See [FLUX_GUIDE.md](FLUX_GUIDE.md)
- **Quick Commands:** 
  - [KUSTOMIZE_QUICK_REF.md](KUSTOMIZE_QUICK_REF.md)
  - [FLUX_QUICK_REF.md](FLUX_QUICK_REF.md)

## 🎓 Learning Path

1. **Start with Kustomize** - Learn the basics
2. **Deploy locally** - Get familiar with the stack
3. **Set up Flux on staging** - Learn GitOps
4. **Graduate to Flux on production** - Full automation

---

**Ready to get started?**
- Kustomize: `./deploy-k8s.sh local apply`
- Flux: `./install-flux.sh && ./flux-bootstrap.sh local --github-user USER --github-token TOKEN`

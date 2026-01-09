# GitHub Actions Quick Reference

## 🚀 Available Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **Build and Push** | Push to main/staging/release | Build Docker images, push to ECR |
| **CI - Lint and Test** | All pushes/PRs | Validation and testing |
| **Deploy (Flux)** | After successful build | Deploy to EKS with Flux |
| **PR Checks** | Pull requests | PR validation and testing |
| **Cleanup Images** | Weekly (Sunday 2 AM) | Remove old ECR images |

## 📋 Common Commands

### Trigger Workflow Manually
```bash
# Via GitHub CLI
gh workflow run build-and-push.yml

# Via web UI
# GitHub → Actions → Select workflow → Run workflow
```

### View Workflow Status
```bash
# List recent runs
gh run list

# Watch current run
gh run watch

# View specific run
gh run view RUN_ID --log
```

### Check Workflow Logs
```bash
# View logs for latest run
gh run view --log

# Download logs
gh run download RUN_ID
```

## 🔄 Environment Flow

```bash
# 1. Development
git checkout main
git add .
git commit -m "feat: new feature"
git push origin main
# → Builds dev images → Updates local overlay

# 2. Staging
git checkout staging
git merge main
git push origin staging
# → Builds staging images → Updates staging overlay → Deploys to staging

# 3. Production
git checkout release
git merge staging
git push origin release
# → Builds production images → Updates production overlay → Deploys to production
```

## 🏷️ Image Tags

| Branch | Environment | Tag Format | Example |
|--------|-------------|------------|---------|
| main | dev | `<service>-dev-<sha>` | `frontend-dev-abc123` |
| staging | staging | `<service>-staging-<sha>` | `frontend-staging-def456` |
| release | production | `<service>-v<number>` | `frontend-v42` |

## 🔐 Required Secrets

```bash
# Set via GitHub CLI
gh secret set AWS_ACCESS_KEY_ID
gh secret set AWS_SECRET_ACCESS_KEY
gh secret set AWS_REGION
gh secret set EKS_CLUSTER_NAME

# Or via web UI
# Settings → Secrets and variables → Actions → New repository secret
```

## 📊 Workflow Status Badges

Add to README.md:

```markdown
![Build](https://github.com/USERNAME/REPO/workflows/Build%20and%20Push%20Docker%20Images%20to%20ECR/badge.svg)
![CI](https://github.com/USERNAME/REPO/workflows/CI%20-%20Lint%20and%20Test/badge.svg)
![Deploy](https://github.com/USERNAME/REPO/workflows/Deploy%20to%20EKS%20with%20Flux/badge.svg)
```

## 🐛 Quick Troubleshooting

### Build Failing?
```bash
# Test Docker build locally
docker build -f task-management-system/frontend.Dockerfile task-management-system

# Check workflow logs
gh run view --log
```

### Deployment Failing?
```bash
# Check Flux status
flux check
flux get kustomizations

# Check cluster access
kubectl get nodes
kubectl get pods -n tms-app
```

### Secrets Not Working?
```bash
# List secrets
gh secret list

# Update secret
gh secret set SECRET_NAME
```

## 📚 Full Documentation

- [Complete Guide](GITHUB_ACTIONS_GUIDE.md)
- [Flux Guide](FLUX_GUIDE.md)
- [Kustomize Guide](k8s/KUSTOMIZE_GUIDE.md)
- [Deployment Overview](DEPLOYMENT_OVERVIEW.md)

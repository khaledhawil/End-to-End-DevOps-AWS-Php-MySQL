# GitHub Actions CI/CD Guide

This project uses GitHub Actions for comprehensive CI/CD pipelines with multi-environment support.

## 🔄 Workflows

### 1. Build and Push (`build-and-push.yml`)

Builds Docker images and pushes them to Amazon ECR.

**Triggers:**
- Push to `main`, `staging`, or `release` branches
- Pull requests to these branches
- Manual dispatch

**Features:**
- ✅ Multi-service build (frontend, users-service, logout-service)
- ✅ Parallel image building with matrix strategy
- ✅ Environment-based tagging (dev, staging, production)
- ✅ Docker layer caching
- ✅ Automatic manifest updates
- ✅ ECR image verification

**Environments:**
- `main` branch → `dev` environment → `dev-<sha>` tags
- `staging` branch → `staging` environment → `staging-<sha>` tags
- `release` branch → `production` environment → `v<run-number>` tags

**Usage:**
```bash
# Automatic on push
git push origin main

# Manual trigger
# Go to Actions → Build and Push → Run workflow
```

---

### 2. CI - Lint and Test (`ci-lint-test.yml`)

Comprehensive testing and validation pipeline.

**Checks:**
- ✅ YAML linting
- ✅ Kustomize validation (all overlays)
- ✅ Flux configuration validation
- ✅ Dockerfile linting (Hadolint)
- ✅ Security scanning (Trivy)
- ✅ PHP syntax validation

**Triggers:**
- All pushes and PRs

**Artifacts:**
- Generated Kubernetes manifests (7-day retention)

---

### 3. Deploy to EKS with Flux (`deploy-flux.yml`)

GitOps deployment using Flux CD.

**Triggers:**
- After successful build-and-push workflow
- Manual dispatch

**Features:**
- ✅ AWS EKS integration
- ✅ Flux reconciliation
- ✅ Deployment health checks
- ✅ Automatic rollout verification

**Prerequisites:**
- Flux must be installed on the cluster
- EKS cluster access configured

---

### 4. PR Checks (`pr-checks.yml`)

Pull request validation and testing.

**Checks:**
- ✅ Semantic PR title validation
- ✅ Merge conflict detection
- ✅ Changed file detection
- ✅ Application build tests
- ✅ Manifest validation
- ✅ Image size checks
- ✅ Automated PR comments with results

**PR Title Format:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `chore:` - Maintenance
- `refactor:` - Code refactoring
- `test:` - Tests
- `ci:` - CI/CD changes

---

## 🔐 Required Secrets

Configure these in GitHub Settings → Secrets and variables → Actions:

### AWS Credentials
```
AWS_ACCESS_KEY_ID          # AWS access key
AWS_SECRET_ACCESS_KEY      # AWS secret key
AWS_REGION                 # Default: us-east-1
```

### EKS Configuration (for deploy-flux.yml)
```
EKS_CLUSTER_NAME          # Name of your EKS cluster
```

### Optional
```
GITHUB_TOKEN              # Automatically provided by GitHub
```

## 📊 Workflow Diagram

```
┌─────────────────┐
│   Git Push      │
└────────┬────────┘
         │
         ├─────────────────────┬─────────────────────┐
         ▼                     ▼                     ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│   CI Lint/Test  │   │  Build & Push   │   │   PR Checks     │
│                 │   │                 │   │   (PRs only)    │
│  • YAML Lint    │   │  • Build Images │   │  • Validation   │
│  • Kustomize    │   │  • Push to ECR  │   │  • Build Test   │
│  • Flux Check   │   │  • Update Yaml  │   │  • PR Comment   │
│  • Docker Lint  │   │  • Tag Images   │   └─────────────────┘
│  • Security     │   └────────┬────────┘
│  • PHP Test     │            │
└─────────────────┘            │
                               ▼
                      ┌─────────────────┐
                      │  Deploy (Flux)  │
                      │                 │
                      │  • Reconcile    │
                      │  • Health Check │
                      │  • Verify       │
                      └─────────────────┘
```

## 🚀 Getting Started

### 1. Configure AWS Credentials

```bash
# Generate AWS access keys in AWS Console
# Add them to GitHub Secrets:
# Settings → Secrets → Actions → New repository secret
```

### 2. First Deployment

```bash
# Push to main branch
git add .
git commit -m "feat: initial deployment"
git push origin main

# Watch the workflow
# GitHub → Actions → Build and Push
```

### 3. Environment Promotion

```bash
# Deploy to staging
git checkout -b staging
git merge main
git push origin staging

# Deploy to production
git checkout -b release
git merge staging
git push origin release
```

## 📋 Environment Strategy

| Branch | Environment | Auto-Deploy | Image Tag | Replicas |
|--------|-------------|-------------|-----------|----------|
| `main` | Local/Dev | ✅ Yes | `dev-<sha>` | 1 |
| `staging` | Staging | ✅ Yes | `staging-<sha>` | 1 |
| `release` | Production | ✅ Yes | `v<number>` | 2 |

## 🔧 Workflow Customization

### Change ECR Repository

Edit `.github/workflows/build-and-push.yml`:

```yaml
env:
  ECR_REGISTRY: YOUR_ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com
  ECR_REPOSITORY: your-repo-name
```

### Add New Service

Add to the matrix in `build-and-push.yml`:

```yaml
strategy:
  matrix:
    service: [frontend, users-service, logout-service, new-service]
```

Create corresponding Dockerfile mapping.

### Adjust Build Trigger Paths

```yaml
on:
  push:
    paths:
      - "task-management-system/**"
      - "your-new-path/**"
```

## 🧪 Testing Workflows Locally

Use [act](https://github.com/nektos/act) to test workflows locally:

```bash
# Install act
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Test CI workflow
act pull_request -W .github/workflows/ci-lint-test.yml

# Test with secrets
act -s AWS_ACCESS_KEY_ID=xxx -s AWS_SECRET_ACCESS_KEY=yyy
```

## 📊 Monitoring

### View Workflow Status

```bash
# GitHub CLI
gh run list

# Watch specific run
gh run watch

# View logs
gh run view --log
```

### Workflow Badges

Add to your README.md:

```markdown
![Build](https://github.com/USERNAME/REPO/workflows/Build%20and%20Push/badge.svg)
![CI](https://github.com/USERNAME/REPO/workflows/CI%20-%20Lint%20and%20Test/badge.svg)
```

## 🐛 Troubleshooting

### Build Fails: AWS Credentials

```bash
# Check secrets are set
gh secret list

# Update secret
gh secret set AWS_ACCESS_KEY_ID < key.txt
```

### Build Fails: Docker Build

```bash
# Test locally
docker build -f task-management-system/frontend.Dockerfile task-management-system

# Check Dockerfile syntax
hadolint task-management-system/frontend.Dockerfile
```

### Kustomize Validation Fails

```bash
# Test locally
kustomize build k8s/overlays/local

# Check YAML syntax
yamllint k8s/
```

### Flux Deployment Fails

```bash
# Check Flux status in cluster
flux check

# View Flux logs
flux logs --all-namespaces --follow

# Manual reconciliation
flux reconcile source git task-management-system
```

## 📈 Best Practices

1. **Branch Protection**
   - Enable required status checks
   - Require PR reviews
   - Require CI to pass

2. **Semantic Commits**
   - Use conventional commit format
   - Helps with automatic changelogs

3. **Environment Variables**
   - Store secrets in GitHub Secrets
   - Use environment-specific configs

4. **Testing**
   - Run workflows on feature branches
   - Test in staging before production

5. **Monitoring**
   - Set up GitHub Actions notifications
   - Monitor workflow execution time
   - Review failed builds promptly

## 🔗 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Action](https://github.com/docker/build-push-action)
- [AWS Actions](https://github.com/aws-actions)
- [Flux GitHub Actions](https://github.com/fluxcd/flux2/tree/main/action)

## 🆘 Getting Help

- Check workflow logs in GitHub Actions tab
- Review this documentation
- See individual workflow files for inline comments
- Check [FLUX_GUIDE.md](FLUX_GUIDE.md) for Flux-specific issues
- Check [KUSTOMIZE_GUIDE.md](k8s/KUSTOMIZE_GUIDE.md) for Kustomize issues

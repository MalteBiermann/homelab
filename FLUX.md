# Flux GitOps Repository Structure

This repository contains Flux CD configuration under kubernetes/production and a local testing stack under kubernetes/testing.

## Directory Structure

```
├── kubernetes/
│   ├── production/              # Flux GitOps configuration
│   │   ├── flux-system/         # Flux system configuration
│   │   │   ├── gotk-sync.yaml   # GitRepository source
│   │   │   └── kustomization.yaml
│   │   └── infrastructure.yaml  # Flux Kustomizations (paths configurable)
│   └── testing/                 # Local testing stack (Kustomize)
│       ├── kustomization.yaml
│       ├── metallb/
│       ├── longhorn/
│       ├── traefik/
│       ├── mosquitto/
│       ├── zigbee2mqtt/
│       ├── homeassistant/
│       ├── booklore/
│       └── shelfmark/
```

## Deployment Order

Flux will deploy in this order (managed by `dependsOn`):

1. **sources** - Helm repositories and other sources
2. **configs** - Namespaces and configurations
3. **controllers** - Applications (Longhorn, Traefik)

These are defined in kubernetes/production/infrastructure.yaml, and the paths should be updated to match your repo layout.

## Quick Start (Local Testing)

```bash
# Apply everything directly (without Git)
kubectl apply -k kubernetes/testing
```

## Production Deployment (Git-based)

### Option 1: Using existing Flux installation

```bash
# Edit the Git URL in kubernetes/production/flux-system/gotk-sync.yaml
# Then apply
kubectl apply -k kubernetes/production/flux-system
```

### Option 2: Bootstrap from scratch

```bash
# Bootstrap Flux and connect to Git repo
flux bootstrap github \
  --owner=YOUR-USERNAME \
  --repository=YOUR-REPO \
  --branch=main \
  --path=kubernetes/production \
  --personal
```

This will:
- Install Flux to your cluster
- Create the repository if it doesn't exist
- Commit Flux manifests to the repo
- Configure Flux to sync from the repo

## Managing Infrastructure

### Check status
```bash
flux get sources git
flux get kustomizations
flux get helmreleases -A
```

### Force reconciliation
```bash
flux reconcile source git flux-system
flux reconcile kustomization sources
flux reconcile kustomization configs
flux reconcile kustomization controllers
```

### Suspend/Resume
```bash
flux suspend kustomization controllers
flux resume kustomization controllers
```

## Adding New Applications

1. **Add Helm repository** (if needed) in your Flux-managed path (per kubernetes/production/infrastructure.yaml)

2. **Create namespace** (if needed) in your Flux-managed path

3. **Add HelmRelease** in your Flux-managed path:
   ```yaml
   ---
   apiVersion: helm.toolkit.fluxcd.io/v2beta1
   kind: HelmRelease
   metadata:
     name: your-app
     namespace: your-namespace
   spec:
     interval: 5m
     chart:
       spec:
         chart: your-chart
         version: '1.0.0'
         sourceRef:
           kind: HelmRepository
           name: your-repo
           namespace: flux-system
     values:
       # your values
   ```

4. **Update kustomization** - Add to your Flux-managed kustomization:
   ```yaml
   resources:
     - your-app.yaml
   ```

5. **Commit and push** - Flux will automatically deploy!

## Private Git Repository

### SSH Key
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "flux" -f flux-ssh

# Add public key to GitHub/GitLab as deploy key

# Create secret
kubectl create secret generic flux-system \
  --from-file=identity=./flux-ssh \
  --from-file=known_hosts=<(ssh-keyscan github.com) \
  -n flux-system

# Update gotk-sync.yaml to use SSH URL and reference the secret
```

### HTTPS Token
```bash
# Create secret
kubectl create secret generic flux-system \
  --from-literal=username=git \
  --from-literal=password=YOUR_TOKEN \
  -n flux-system

# Update gotk-sync.yaml to reference the secret
```

## Benefits of This Structure

✅ **Separation of Concerns** - Sources, configs, and apps are separate
✅ **Explicit Dependencies** - Clear deployment order
✅ **Reusability** - Infrastructure can be shared across clusters
✅ **Scalability** - Easy to add new clusters or applications
✅ **GitOps Best Practices** - Follows Flux CD conventions

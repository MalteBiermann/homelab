# Quick Deployment Guide

## Initial Setup

```bash
# 1. Deploy infrastructure
cd terraform
tofu apply

# 2. Save credentials (from project root)
cd ..
tofu -chdir=terraform output -raw kubeconfig > kubeconfig
tofu -chdir=terraform output -raw talosconfig > talosconfig
export KUBECONFIG=$PWD/kubeconfig

# 3. Deploy Flannel CNI
./kubernetes/scripts/deploy-flannel.sh

# 4. Install Flux CD
./kubernetes/scripts/deploy-flux.sh

# 5. Deploy apps via Flux (local testing)
kubectl apply -k kubernetes/testing
```

## Production with Git

```bash
# After steps 1-4 above:

# 5a. Create Git repo and push entire directory
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR-USER/YOUR-REPO.git
git push -u origin main

# 5b. Update kubernetes/production/flux-system/gotk-sync.yaml with your repo URL
# Edit: kubernetes/production/flux-system/gotk-sync.yaml

# 5c. Ensure kubernetes/production/infrastructure.yaml points to your paths
# 5d. Apply Flux GitRepository
kubectl apply -k kubernetes/production/flux-system
```

## Verify Everything

```bash
# Nodes
kubectl get nodes

# Flannel
kubectl get pods -n kube-flannel

# Flux
flux get all

# Longhorn
kubectl get pods -n longhorn-system
kubectl get storageclass

# Traefik  
kubectl get svc -n traefik
```

## Common Operations

```bash
# Force Flux sync
flux reconcile source git flux-system

# Check Helm releases
flux get helmreleases -A

# Suspend an app
flux suspend helmrelease longhorn -n longhorn-system

# Resume an app
flux resume helmrelease longhorn -n longhorn-system

# View logs
flux logs --level=info --follow

# Traefik dashboard
kubectl port-forward -n traefik svc/traefik 9000:9000
# Visit: http://localhost:9000/dashboard/
```

## Cleanup

```bash
# Suspend Flux (prevents re-deployment)
flux suspend kustomization controllers

# Remove apps
kubectl delete -k kubernetes/testing

# Destroy infrastructure
cd terraform
tofu destroy
```

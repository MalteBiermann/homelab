#!/bin/bash
set -e

echo "Installing Flux CD..."

# Check if flux CLI is installed
if ! command -v flux &> /dev/null; then
    echo "Error: flux CLI not found. Install it first:"
    echo "  brew install fluxcd/tap/flux"
    echo "  or: curl -s https://fluxcd.io/install.sh | sudo bash"
    exit 1
fi

# Set kubeconfig
#export KUBECONFIG=$PWD./kubeconfig

# Check prerequisites
echo "Checking prerequisites..."
flux check --pre

# Install Flux components
echo "Installing Flux to the cluster..."
flux install

# Wait for Flux to be ready
echo "Waiting for Flux controllers to be ready..."
kubectl wait --for=condition=ready pod -l app=source-controller -n flux-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=kustomize-controller -n flux-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=helm-controller -n flux-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=notification-controller -n flux-system --timeout=300s

echo "Flux installed successfully!"
kubectl get pods -n flux-system

echo ""
echo "Next steps:"
echo "1. Create a Git repository for your manifests"
echo "2. Apply the GitRepository and Kustomization resources from flux-config/"
echo "3. Flux will automatically deploy Longhorn and Traefik"

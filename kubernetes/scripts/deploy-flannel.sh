#!/bin/bash
set -e

echo "Deploying Flannel CNI..."

# Download and apply Flannel manifest
kubectl --kubeconfig=./kubeconfig apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo "Waiting for Flannel to be ready..."
kubectl --kubeconfig=./kubeconfig wait --for=condition=ready pod -l app=flannel -n kube-flannel --timeout=300s || true

# Give it a moment to stabilize
sleep 5

echo "Flannel deployment status:"
kubectl --kubeconfig=./kubeconfig get pods -n kube-flannel
kubectl --kubeconfig=./kubeconfig get nodes

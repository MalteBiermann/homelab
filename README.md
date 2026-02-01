# Terraform Proxmox VM Deployment

This Terraform configuration creates VMs on Proxmox based on the specifications in the plan.

## Prerequisites

- Terraform >= 1.5.0 or OpenTofu >= 1.6.0
- Proxmox API token with VM creation permissions
- Internet access on Proxmox host (to download Talos ISO)

## Setup

1. **Copy the example variables file:**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars` with your values:**
   - Update Proxmox API credentials
   - Adjust VM specifications as needed
   - Configure network settings

3. **Initialize Terraform/OpenTofu:**
   ```bash
   cd terraform
   tofu init
   ```

**Note:** If you're updating from a previous version, run `tofu init -upgrade` to install the new time provider.

## Usage

### 1. Deploy Infrastructure

```bash
# From the terraform directory
cd terraform

# Review the plan
tofu plan

# Apply the configuration (creates VMs and Talos cluster)
tofu apply

# Save cluster access configs (from project root)
cd ..
tofu -chdir=terraform output -raw kubeconfig > kubeconfig
tofu -chdir=terraform output -raw talosconfig > talosconfig
export KUBECONFIG=$PWD/kubeconfig
```

### 2. Deploy Flannel CNI

After the cluster is created, deploy Flannel for pod networking:

```bash
./kubernetes/scripts/deploy-flannel.sh
```

This will:
- Download and apply the latest Flannel manifest
- Wait for Flannel pods to become ready
- Verify deployment

### 3. Deploy Flux CD (GitOps)

Install Flux to manage Longhorn and Traefik:

```bash
./kubernetes/scripts/deploy-flux.sh
```

This will:
- Install Flux controllers (source, kustomize, helm, notification)
- Wait for Flux to be ready
- Prepare the cluster for GitOps

### 4. Deploy Manifests

**Option A: Local/Testing (without Git):**
```bash
kubectl apply -k kubernetes/testing
```

**Option B: Production (with Git repository):**

1. Create a Git repository and push this entire directory
2. Edit `kubernetes/production/flux-system/gotk-sync.yaml` with your repository URL
3. Ensure `kubernetes/production/infrastructure.yaml` points to the paths you want to sync
4. Apply the Flux configuration:
   ```bash
   kubectl apply -k kubernetes/production/flux-system
   ```

Flux will automatically deploy:
- **Longhorn** - Distributed storage with iSCSI (3 replicas, 50GB per node)
- **Traefik** - Ingress controller with LoadBalancer (HTTP/HTTPS/custom ports)

### 5. Deploy Applications

All applications are in `kubernetes/testing/`, organized one folder per app:

```bash
# Deploy all applications at once
kubectl apply -k kubernetes/testing/

# Or deploy individually
kubectl apply -k kubernetes/testing/metallb/
kubectl apply -k kubernetes/testing/longhorn/
kubectl apply -k kubernetes/testing/traefik/
kubectl apply -k kubernetes/testing/homeassistant/
kubectl apply -k kubernetes/testing/mosquitto/
kubectl apply -k kubernetes/testing/zigbee2mqtt/
kubectl apply -k kubernetes/testing/booklore/
kubectl apply -k kubernetes/testing/shelfmark/
```

#### Available Applications

| Application | Namespace | Port | Storage | Purpose |
|------------|-----------|------|---------|---------|
| **Longhorn** | longhorn-system | — | 50GB/node | Distributed storage backend |
| **Traefik** | traefik | 80, 443, 1883 | — | Ingress controller & load balancer |
| **Home Assistant** | homeassistant | HTTP via Traefik | 5Gi | Smart home automation platform |
| **Mosquitto** | mosquitto | 1883, 9001 | 1Gi | MQTT message broker |
| **Zigbee2MQTT** | zigbee2mqtt | HTTP via Traefik | 1Gi | Zigbee to MQTT bridge |
| **BookLore** | booklore | HTTP via Traefik | 5Gi (books) + 1Gi (app) | Self-hosted e-book library |
| **Shelfmark** | shelfmark | HTTP via Traefik | 1Gi | Library catalog app |

See [FLUX.md](FLUX.md) for detailed Flux usage and GitOps workflows.

### 5. Verify Deployment

```bash
# Check all nodes are Ready
kubectl get nodes

# Check Flannel
kubectl get pods -n kube-flannel

# Check Flux
flux get sources helmrepository
flux get helmreleases -A

# Check Longhorn
kubectl get pods -n longhorn-system
kubectl get storageclass

# Check Traefik
kubectl get pods -n traefik
kubectl get svc -n traefik

# Check applications
kubectl get pods -A | grep -E "homeassistant|mosquitto|zigbee2mqtt|booklore"
```

### 6. Access Applications

**Traefik Dashboard:**
```bash
kubectl port-forward -n traefik $(kubectl get pods -n traefik -l app.kubernetes.io/name=traefik -o name) 9000:9000
# Open http://localhost:9000/dashboard/
```

**Home Assistant:**
- Via Traefik (HTTP): `http://homeassistant.local.biermann.uk`
- Or port-forward: `kubectl port-forward -n homeassistant svc/homeassistant 8123:8123`

**BookLore:**
- Via Traefik (HTTP): `http://booklore.local.biermann.uk`
- Access UI to add books to `/books` PVC

**Mosquitto MQTT:**
- Host: `mosquitto.mosquitto.svc.cluster.local:1883`
- WebSocket: `mosquitto.mosquitto.svc.cluster.local:9001`

**Zigbee2MQTT:**
- Requires USB Zigbee coordinator device to function
- Via Traefik (HTTP): `http://zigbee2mqtt.local.biermann.uk`

**Shelfmark:**
- Via Traefik (HTTP): `http://shelfmark.local.biermann.uk`

### 7. Destroy resources (when needed)

```bash
cd terraform
tofu destroy
```

**Note:** Longhorn and Traefik are managed by Flux. If you want to remove them before destroying the cluster:
```bash
flux suspend kustomization controllers
kubectl delete -k kubernetes/testing
```

## Configuration

### Cluster Architecture
- **3 Control Plane Nodes** (can also run workloads)
- All nodes have both control plane and worker capabilities
- High availability with 3-node etcd cluster
- **iSCSI Tools:** Included in Talos image for Longhorn support

### VM Specifications
- **Count:** 3 VMs (configurable)
- **CPU:** 2 cores per VM (default)
- **Memory:** 2048 MB per VM (default)
- **Boot Disk:** 10 GB (local-lvm)
- **Data Disk:** 50 GB (nvme-lvm) - Used by Longhorn
- **VM IDs:** 900-902

### Network
- **vmbr0 (ens18):** Static IPs - Main cluster communication (Kubernetes API, etcd, Talos API)
- **Cluster bridge (ens19):** Static IPs - Intra-cluster traffic
- Gateway and DNS configured via terraform.tfvars
- **CNI:** Flannel (deployed separately after cluster creation)
- **Ingress:** Traefik (managed by Flux CD)

### Storage
- **System:** Talos ISO downloaded from the official GitHub release by default
- **Boot Disks:** local-lvm storage pool
- **Data Disks:** nvme-lvm storage pool (for Longhorn)
- **Storage Class:** Longhorn (managed by Flux, provides distributed block storage)

## Outputs

After applying, OpenTofu will output:
- VM IDs, names, and MAC addresses  
- Configured static IPv4 addresses
- Talos machine configurations (for manual intervention if needed)
- Talosconfig for cluster management
- Kubernetes cluster endpoint
- **Kubeconfig** - Ready to use for kubectl access

## Automated Deployment

The Terraform configuration automates the infrastructure deployment:
1. Downloads Talos ISO (with iSCSI tools) to Proxmox
2. Creates VMs with static IP configuration and dual disks
3. Applies Talos machine configuration to each node
4. Bootstraps the Kubernetes cluster
5. Retrieves kubeconfig and talosconfig automatically

After Terraform completes, use the deployment scripts:
- `./kubernetes/scripts/deploy-flannel.sh` - Deploys Flannel CNI for pod networking
- `./kubernetes/scripts/deploy-flux.sh` - Deploys Flux CD for GitOps
- Then Flux manages Longhorn (storage) and Traefik (ingress)

## Cluster Details

The cluster is configured with:
- **Talos Version:** v1.12.2
- **Kubernetes Version:** v1.35.0
- **CNI:** Flannel v0.28.0 (deployed via script)
- **GitOps:** Flux CD with source, kustomize, helm, and notification controllers
- **Storage:** Longhorn v1.11.x (managed by Flux, 3 replicas, dedicated 50GB disk per node)
- **Ingress:** Traefik v39.x (managed by Flux, LoadBalancer with custom ports)
- **Network:** Dual interfaces with static IPs
- **High Availability:** 3 control plane nodes with etcd
- **Scheduling:** All nodes can run workloads (`allowSchedulingOnControlPlanes: true`)
- **iSCSI Support:** Built-in for Longhorn storage operations
- **Disk Mount:** /dev/sdb1 (50GB) mounted to /var/lib/longhorn on all nodes

## Infrastructure Components

### Storage Architecture
- **Longhorn** provides distributed block storage
- Each node has 50GB dedicated storage at `/var/lib/longhorn`
- Kernel modules enabled: iscsi_tcp, dm_crypt
- Kubelet extraMounts with rshared propagation for multi-replica support
- Storage policy: Retain (keeps data after volume deletion)

### Networking Architecture
- **Traefik** entrypoints:
  - `web`: Port 80 (HTTP)
  - `websecure`: Port 443 (HTTPS)
- `mqtt`: Port 1883 (TCP)
- All traffic routed through LoadBalancer service (NodePort for lab environments)
- Applications use IngressRoute for HTTP routing; Mosquitto uses IngressRouteTCP

### Application Configuration
Each application follows the same pattern:
- **Namespace**: Isolated with pod security policies
- **Storage**: PersistentVolumeClaims using Longhorn StorageClass
- **Secrets**: Kubernetes Secrets for credentials
- **Services**: ClusterIP for internal communication
- **Routing**: IngressRouteTCP/Ingress through Traefik
- **Resources**: CPU/Memory requests and limits

## Manual Cluster Management

After deployment, you can manage the cluster with talosctl:

```bash
# Check cluster health
talosctl --talosconfig ./talosconfig health

# View node status
talosctl --talosconfig ./talosconfig get members

# Access a node
talosctl --talosconfig ./talosconfig -n <node-ip> dashboard
```

**Note:** Replace `<node-ip>` with an actual node IP from `terraform.tfvars` (e.g., 10.0.5.85).

## Notes

- The Talos ISO is downloaded from the official Talos releases by default
- iSCSI tools are installed via Talos upgrade in Terraform to support Longhorn
- The `terraform.tfvars` file contains secrets and should not be committed to version control
- SSL verification is disabled by default (`insecure = true`). Change this in production environments
- VMs are set to start automatically (`on_boot = true`)
- Commands use `tofu` (OpenTofu) but work identically with `terraform`
- Flannel and Longhorn are deployed separately to avoid Terraform dependency issues during cluster lifecycle operations

## Troubleshooting

### Flannel deployment fails
- Ensure all nodes are in Ready state before deploying Flannel
- Wait 100 seconds after cluster bootstrap for Kubernetes API to stabilize

### Longhorn deployment fails
- Verify Flannel is fully deployed first (`kubectl get pods -n kube-flannel`)
- Check that nodes have iSCSI tools: `talosctl get extensions`
- If no extensions shown, nodes may be running from ISO - run upgrade to install to disk
- Check namespace has `pod-security.kubernetes.io/enforce=privileged` label

### Traefik not getting LoadBalancer IP
- Check your network supports LoadBalancer type services
- Use NodePort if LoadBalancer is not available
- Or use port-forward for testing

### Flux not syncing
- Check Flux controllers: `kubectl get pods -n flux-system`
- View logs: `flux logs --follow`
- Verify Git repository is accessible
- Check for SSH key or token issues with private repos

### Cluster destroy hangs
- Flux-managed apps may block destroy if using finalizers
- Suspend Flux first: `flux suspend kustomization controllers`
- Delete apps: `kubectl delete -k kubernetes/testing`
- Then run `tofu destroy`

# Proxmox Configuration
proxmox_api_url          = "https://pve.server:8006/api2/json"
proxmox_api_token_id     = "terraform@pam!tf"
proxmox_node             = "pve"

# VM Configuration
vm_count       = 3  # 3 control plane nodes (can also run workloads)
vm_name_prefix = "vm"
vm_id_start    = 900

# VM Hardware
vm_cpu_cores = 4
vm_cpu_type  = "host"  # Options: host, kvm64, qemu64, etc.
vm_memory    = 8192    # Memory in MB

# VM Disk
vm_disk_size      = 15       # Disk size in GB (resized from 10GB)
vm_disk_interface = "scsi0"  # Options: scsi0, sata0, virtio0, ide0
vm_disk_format    = "raw"    # Options: raw, qcow2

# Data Disk (for Longhorn storage)
data_disk_size         = 50        # Data disk size in GB
data_disk_storage_pool = "nvme-lvm" # Storage pool for data disks

# Network Configuration
# eth0 (vmbr0) - Static IP for external communication
network_bridge = "vmbr0"  # Bridge for eth0 (Static IP)

# Static IP Configuration (eth0)
vm_ipv4_addresses = [
  "10.0.5.85/24",
  "10.0.5.86/24",
  "10.0.5.87/24"
]
vm_ipv4_gateway = "10.0.5.1"

# Cluster Network Configuration
# eth1 (vmbr2) - Intra-cluster communication only
cluster_network_bridge = "vmbr2"  # Bridge for eth1 (cluster network)

vm_cluster_ipv4_addresses = [
  "10.10.0.10/24",
  "10.10.0.11/24",
  "10.10.0.12/24"
]

# Storage Configuration
storage_pool   = "local-lvm" # Storage pool for VM disks
iso_datastore  = "local"     # Datastore for ISO files

# VM Behavior
vm_os_type     = "l26"  # Operating system type (l26 = Linux 2.6+)
vm_qemu_agent  = true   # Enable QEMU guest agent
vm_on_boot     = true   # Start VM on host boot
vm_started     = true   # Start VM after creation

# Talos Image Configuration
talos_version    = "v1.12.6"
talos_image_url  = "https://factory.talos.dev/image/dc7b152cb3ea99b821fcb7340ce7168313ce393d663740b791c36f6e95fc8586/v1.12.6/nocloud-amd64.iso"
# Use official GitHub release (more reliable than Image Factory)
#talos_image_url = "https://github.com/siderolabs/talos/releases/download/v1.12.6/nocloud-amd64.iso"

# Talos Cluster Configuration
talos_cluster_name     = "talos-proxmox-cluster"
kubernetes_version     = "1.35.0"
talos_cluster_endpoint = ""  # Leave empty to use first node IP, or set VIP/LB address




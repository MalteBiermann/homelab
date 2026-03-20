variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 3
}

variable "vm_name_prefix" {
  description = "Prefix for VM names"
  type        = string
  default     = "vm"
}

variable "vm_cpu_cores" {
  description = "Number of CPU cores per VM"
  type        = number
  default     = 2
}

variable "vm_cpu_type" {
  description = "CPU type (host, kvm64, etc.)"
  type        = string
  default     = "host"
}

variable "vm_memory" {
  description = "Memory in MB per VM"
  type        = number
  default     = 2048
}

variable "vm_disk_size" {
  description = "Boot disk size in GB per VM"
  type        = number
  default     = 10
}

variable "data_disk_size" {
  description = "Data disk size in GB per VM (for Longhorn storage)"
  type        = number
  default     = 50
}

variable "data_disk_storage_pool" {
  description = "Storage pool for data disks"
  type        = string
  default     = "nvme-lvm"
}

variable "vm_disk_interface" {
  description = "Disk interface (scsi0, sata0, virtio0, etc.)"
  type        = string
  default     = "scsi0"
}

variable "vm_disk_format" {
  description = "Disk file format (raw, qcow2)"
  type        = string
  default     = "raw"
}

variable "network_bridge" {
  description = "Network bridge for eth0 (Static IP)"
  type        = string
  default     = "vmbr0"
}

variable "vm_ipv4_addresses" {
  description = "List of static IPv4 addresses for VMs (e.g., ['10.0.5.85/24', '10.0.5.86/24', '10.0.5.87/24'])"
  type        = list(string)
}

variable "vm_ipv4_gateway" {
  description = "IPv4 gateway for VMs"
  type        = string
}

variable "vm_cluster_ipv4_addresses" {
  description = "List of static IPv4 addresses for cluster network (e.g., ['10.10.0.10/24', '10.10.0.11/24', '10.10.0.12/24'])"
  type        = list(string)
}

variable "cluster_network_bridge" {
  description = "Network bridge for intra-cluster communication"
  type        = string
}

variable "vm_id_start" {
  description = "Starting VM ID"
  type        = number
  default     = 900
}

variable "storage_pool" {
  description = "Storage pool for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "iso_datastore" {
  description = "Datastore for ISO files"
  type        = string
  default     = "local"
}

variable "vm_os_type" {
  description = "Operating system type (l26 for Linux 2.6+, l24 for Linux 2.4, etc.)"
  type        = string
  default     = "l26"
}

variable "vm_qemu_agent" {
  description = "Enable QEMU guest agent"
  type        = bool
  default     = true
}

variable "vm_on_boot" {
  description = "Start VM on boot"
  type        = bool
  default     = true
}

variable "vm_started" {
  description = "Start VM after creation"
  type        = bool
  default     = true
}

variable "talos_version" {
  description = "Talos version for naming the downloaded ISO"
  type        = string
  default     = "v1.12.6"
}

variable "talos_image_url" {
  description = "URL to download Talos ISO"
  type        = string
  default     = "https://github.com/siderolabs/talos/releases/download/v1.12.6/nocloud-amd64.iso"
}

variable "talos_cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
  default     = "talos-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version to install"
  type        = string
  default     = "1.35.2"
}

variable "talos_cluster_endpoint" {
  description = "Cluster endpoint URL (VIP or load balancer)"
  type        = string
  default     = ""
}


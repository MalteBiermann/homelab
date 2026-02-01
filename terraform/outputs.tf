output "vm_ids" {
  description = "IDs of created VMs"
  value       = proxmox_virtual_environment_vm.vm[*].vm_id
}

output "vm_names" {
  description = "Names of created VMs"
  value       = proxmox_virtual_environment_vm.vm[*].name
}

output "vm_mac_addresses" {
  description = "MAC addresses of VMs"
  value       = [for vm in proxmox_virtual_environment_vm.vm : vm.mac_addresses]
}

output "vm_ipv4_addresses" {
  description = "IPv4 addresses of VMs (static IPs)"
  value       = [for vm in proxmox_virtual_environment_vm.vm : vm.ipv4_addresses]
}

output "talos_controlplane_config" {
  description = "Talos control plane machine configurations per node"
  value       = var.enable_talos ? { for i, config in data.talos_machine_configuration.controlplane : i => config.machine_configuration } : {}
  sensitive   = true
}

output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = var.talos_cluster_endpoint != "" ? var.talos_cluster_endpoint : "https://${split("/", var.vm_ipv4_addresses[0])[0]}:6443"
}

output "talosconfig" {
  description = "Talos configuration for cluster management"
  value       = var.enable_talos ? data.talos_client_configuration.this[0].talos_config : null
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubernetes configuration for cluster access"
  value       = var.enable_talos ? talos_cluster_kubeconfig.this[0].kubeconfig_raw : null
  sensitive   = true
}


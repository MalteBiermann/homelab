# Terraform Proxmox VM Creation - Project Plan

## Objective
Create VMs on Proxmox using Terraform

---

## Proxmox Details

**Proxmox Host**
- API URL: [e.g., https://192.168.1.5:8006/api2/json]
- Node Name: [e.g., pve]
- Storage: [e.g., local-lvm]

**Authentication**
- API Token ID: [e.g., terraform@pam!mytoken]
- API Token Secret: [Store securely]

---

## VM Configuration

### Number of VMs
- Total VMs: 3

### VM Specifications
```
VM ID Range: 900-999
Name Pattern: vm-01, vm-02, vm-03, ...
CPU Cores: 2
Memory (MB): 2048
Disk Size (GB): 10
```

### Network Settings
```
Network Bridge: vmbr0, vmb1
IP Assignment: vmbr0 - DHCP, vmb1 - Static

If Static:
  IP Addresses: 10.10.10.100-150
  Gateway: 10.10.10.1
  DNS: 
```

### OS/Template
```
Template ID: [e.g., 9000]
OR
ISO: https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/v1.12.2/nocloud-amd64.iso
```

---

## Terraform Requirements

### Files Needed
- `main.tf` - VM resource definitions
- `variables.tf` - Input variables
- `terraform.tfvars` - Variable values (don't commit secrets!)
- `provider.tf` - Proxmox provider config

### Provider Version
```hcl
proxmox provider: bgp/proxmox
```

---

## Variables to Define

**Required:**
- `proxmox_api_url`
- `proxmox_api_token_id`
- `proxmox_api_token_secret`
- `proxmox_node`
- `vm_count`
- `vm_name_prefix`

**Optional:**
- `vm_cpu_cores` (default: 2)
- `vm_memory` (default: 2048)
- `vm_disk_size` (default: 20)
- `network_bridge` (default: vmbr0)

---

## Implementation Steps

1. **Setup**
   - [ ] Install Terraform
   - [ ] Create Proxmox API token
   - [ ] Test API access

2. **Create Terraform Files**
   - [ ] Write provider.tf
   - [ ] Write variables.tf
   - [ ] Write main.tf with VM resources
   - [ ] Create terraform.tfvars

3. **Deploy**
   - [ ] Run `terraform init`
   - [ ] Run `terraform plan`
   - [ ] Review planned changes
   - [ ] Run `terraform apply`

4. **Verify**
   - [ ] Check VMs in Proxmox UI
   - [ ] Verify VMs are running
   - [ ] Test network connectivity (if applicable)

---

## Expected Output

```terraform
output "vm_ids" {
  description = "IDs of created VMs"
}

output "vm_names" {
  description = "Names of created VMs"
}

output "vm_ips" {
  description = "IP addresses (if static)"
}
```

# Download Talos ISO from URL
resource "proxmox_virtual_environment_download_file" "talos_image" {
  node_name           = var.proxmox_node
  content_type        = "iso"
  datastore_id        = var.iso_datastore
  file_name           = "talos-${var.talos_version}-nocloud-amd64.iso"
  url                 = var.talos_image_url
  overwrite           = true
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "vm" {
  count = var.vm_count

  name        = "${var.vm_name_prefix}-${format("%02d", count.index + 1)}"
  description = "VM created by Terraform"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id_start + count.index

  depends_on = [proxmox_virtual_environment_download_file.talos_image]

  cpu {
    cores = var.vm_cpu_cores
    type  = var.vm_cpu_type
  }

  memory {
    dedicated = var.vm_memory
  }

  # Boot disk
  disk {
    datastore_id = var.storage_pool
    file_format  = var.vm_disk_format
    interface    = var.vm_disk_interface
    size         = var.vm_disk_size
  }

  # Data disk for Longhorn storage
  disk {
    datastore_id = var.data_disk_storage_pool
    file_format  = var.vm_disk_format
    interface    = "scsi1"
    size         = var.data_disk_size
    ssd          = true
  }

  # Network interface on main bridge - eth0
  network_device {
    bridge = var.network_bridge
  }

  # Network interface on cluster bridge - eth1
  network_device {
    bridge = var.cluster_network_bridge
  }

  initialization {
    # eth0 - Static IP (main network)
    ip_config {
      ipv4 {
        address = var.vm_ipv4_addresses[count.index]
        gateway = var.vm_ipv4_gateway
      }
    }
    # eth1 - Static IP (cluster network)
    ip_config {
      ipv4 {
        address = var.vm_cluster_ipv4_addresses[count.index]
      }
    }
  }

  cdrom {
    enabled = true
    file_id = proxmox_virtual_environment_download_file.talos_image.id
    interface = "ide3"
  }

  boot_order = [var.vm_disk_interface, "ide3"]

  operating_system {
    type = var.vm_os_type
  }

  agent {
    enabled = var.vm_qemu_agent
  }

  on_boot = var.vm_on_boot
  started = var.vm_started
  
  stop_on_destroy = true  # Hard shutdown - don't wait for graceful stop
}

# Generate Talos machine secrets
resource "talos_machine_secrets" "this" {
  lifecycle {
    ignore_changes = all
  }
}

# Generate Talos machine configuration for each control plane node with unique static IPs
data "talos_machine_configuration" "controlplane" {
  count = var.vm_count

  cluster_name       = var.talos_cluster_name
  cluster_endpoint   = var.talos_cluster_endpoint != "" ? var.talos_cluster_endpoint : "https://${split("/", var.vm_ipv4_addresses[0])[0]}:6443"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  kubernetes_version = var.kubernetes_version
  
  docs     = false
  examples = false
  
  config_patches = [
    yamlencode({
      machine = {
        install = {
          extensions = [
            {
              image = "ghcr.io/siderolabs/iscsi-tools:v0.1.6"
            }
          ]
        }
        # Mount data disk to /var/lib/longhorn
        disks = [
          {
            device = "/dev/sdb"
            partitions = [
              {
                mountpoint = "/var/lib/longhorn"
              }
            ]
          }
        ]
        # Load kernel modules required by Longhorn
        kernel = {
          modules = [
            { name = "iscsi_tcp" },
            { name = "dm_crypt" }
          ]
        }
        # Configure kubelet for Longhorn with proper mount propagation
        kubelet = {
          nodeIP = {
            validSubnets = ["10.10.0.0/24"]
          }
          extraMounts = [
            {
              destination = "/var/lib/longhorn"
              type        = "bind"
              source      = "/var/lib/longhorn"
              options     = ["bind", "rshared", "rw"]
            }
          ]
        }
        time = {
          # Configure NTP servers
          servers = [
            "pool.ntp.org",
          ]
        }
        network = {
          # Configure network interfaces
          interfaces = [
            {
              interface = "ens18"
              dhcp      = false
              addresses = [var.vm_ipv4_addresses[count.index]]
              routes = [
                {
                  gateway = var.vm_ipv4_gateway
                }
              ]
            },
            {
              interface = "ens19"
              dhcp      = false
              addresses = [var.vm_cluster_ipv4_addresses[count.index]]
            }
          ]
          nameservers = [var.vm_ipv4_gateway]
        }
        features = {
          hostDNS = {
            enabled = true # Recommended for Talos
          }
          kubernetesTalosAPIAccess = {
            enabled = true
            allowedRoles = ["os:reader"]
            allowedKubernetesNamespaces = ["kube-system"]
          }
        }
        # Override default node labels to remove the external load balancer exclusion
        # and mark nodes that should peer/advertise with MetalLB
        nodeLabels = {
          "metallb.io/peer" = "true"
        }
      }
      cluster = {
        allowSchedulingOnControlPlanes = true
        network = {
          cni = {
            name = "none"
          }
        }
      }
    })
  ]
}

# Generate talosconfig
data "talos_client_configuration" "this" {
  cluster_name         = var.talos_cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for ip in var.vm_ipv4_addresses : split("/", ip)[0]]
  endpoints            = [for ip in var.vm_ipv4_addresses : split("/", ip)[0]]
}

# Apply Talos configuration to each node
resource "talos_machine_configuration_apply" "controlplane" {
  count = var.vm_count

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane[count.index].machine_configuration
  
  endpoint = split("/", var.vm_ipv4_addresses[count.index])[0]
  node     = split("/", var.vm_ipv4_addresses[count.index])[0]

  depends_on = [
    proxmox_virtual_environment_vm.vm
  ]

  lifecycle {
    ignore_changes = all
  }
}

# Bootstrap the Talos cluster on the first control plane node
resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = split("/", var.vm_ipv4_addresses[0])[0]
  node                 = split("/", var.vm_ipv4_addresses[0])[0]

  depends_on = [
    talos_machine_configuration_apply.controlplane
  ]

  lifecycle {
    ignore_changes = all
  }
}

# Upgrade Talos nodes to specified version with extensions
resource "null_resource" "talos_upgrade" {
  count = var.vm_count

  triggers = {
    talos_version = var.talos_version
    node_ip       = split("/", var.vm_ipv4_addresses[count.index])[0]
  }

  provisioner "local-exec" {
    command     = <<-EOT
      # Wait for node to be ready before upgrading
      sleep 120
      
      # Write temporary talosconfig for this upgrade
      cat > /tmp/talosconfig-upgrade-${split("/", var.vm_ipv4_addresses[count.index])[0]}.yaml <<'EOF'
    ${data.talos_client_configuration.this.talos_config}
    EOF
      export TALOSCONFIG=/tmp/talosconfig-upgrade-${split("/", var.vm_ipv4_addresses[count.index])[0]}.yaml
      
      # Check if node is already at target version
      CURRENT_VERSION=$(talosctl -n ${split("/", var.vm_ipv4_addresses[count.index])[0]} version --short 2>/dev/null | grep "Tag:" | awk '{print $2}' || echo "unknown")
      
      if [ "$CURRENT_VERSION" != "${var.talos_version}" ]; then
        echo "Upgrading node from $CURRENT_VERSION to ${var.talos_version}"
        talosctl -n ${split("/", var.vm_ipv4_addresses[count.index])[0]} upgrade \
          --image factory.talos.dev/nocloud-installer/dc7b152cb3ea99b821fcb7340ce7168313ce393d663740b791c36f6e95fc8586:${var.talos_version} \
          --wait=false
      else
        echo "Node already at version ${var.talos_version}, skipping upgrade"
      fi
      
      rm -f /tmp/talosconfig-upgrade-${split("/", var.vm_ipv4_addresses[count.index])[0]}.yaml
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    talos_machine_bootstrap.this,
    talos_machine_configuration_apply.controlplane
  ]
  
  lifecycle {
    ignore_changes = all
  }
}

# Retrieve kubeconfig after cluster is bootstrapped
resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = split("/", var.vm_ipv4_addresses[0])[0]
  node                 = split("/", var.vm_ipv4_addresses[0])[0]

  depends_on = [
    talos_machine_bootstrap.this,
    null_resource.talos_upgrade
  ]

  lifecycle {
    ignore_changes = all
  }
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.93"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.10.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure = true # Set to false if using valid SSL certificates
  
  ssh {
    agent = true
  }
}



provider "kubernetes" {
  host                   = yamldecode(talos_cluster_kubeconfig.this.kubeconfig_raw).clusters[0].cluster.server
  cluster_ca_certificate = base64decode(yamldecode(talos_cluster_kubeconfig.this.kubeconfig_raw).clusters[0].cluster.certificate-authority-data)
  client_certificate     = base64decode(yamldecode(talos_cluster_kubeconfig.this.kubeconfig_raw).users[0].user.client-certificate-data)
  client_key             = base64decode(yamldecode(talos_cluster_kubeconfig.this.kubeconfig_raw).users[0].user.client-key-data)
}

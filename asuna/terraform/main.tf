terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10.0"
    }
    flux = {
      source = "fluxcd/flux"
    }
    github = {
      source  = "integrations/github"
      version = ">=5.18.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox.api_url
  pm_user         = var.proxmox.username
  pm_password     = var.pm_password
  pm_tls_insecure = true
  // pm_debug = true
}

provider "github" {
  owner = var.flux.github_org
  token = var.github_token
}

provider "flux" {
  kubernetes = {
    host                   = data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
    client_certificate     = base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  }
  git = {
    url = "ssh://git@github.com/${var.flux.github_org}/${var.flux.github_repo}.git"
    ssh = {
      username    = "git"
      private_key = tls_private_key.flux.private_key_pem
    }
    branch = var.flux.github_branch
  }
}

provider "kubernetes" {
  host                   = data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
  client_certificate     = base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
}

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "this" {
  title      = "Flux TF"
  repository = var.flux.github_repo
  key        = tls_private_key.flux.public_key_openssh
  read_only  = "false"
}

resource "flux_bootstrap_git" "this" {
  depends_on = [
    github_repository_deploy_key.this,
    data.talos_cluster_kubeconfig.this
  ]
  path           = var.flux.flux_path
  network_policy = true
  interval       = "15m"
  version        = var.flux.version
}

resource "kubernetes_secret" "age_secret" {
  metadata {
    name      = var.flux.sops_secret_name
    namespace = "flux-system"
    labels = {
      "sensitive" = "true"
    }
  }
  data = {
    "age.agekey" = file("${path.cwd}/${var.flux.sops_key_path}")
  }
  depends_on = [
    flux_bootstrap_git.this
  ]
}

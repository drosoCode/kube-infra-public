
resource "talos_machine_secrets" "this" {}

resource "talos_machine_bootstrap" "bootstrap" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = var.controlplane_address
  node                 = var.controlplane_address
  depends_on = [
    talos_machine_configuration_apply.vm_talos_apply
  ]
}

# create the talos client config
data "talos_client_configuration" "this" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [var.controlplane_address]
}

# kubeconfig
data "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.controlplane_address
  wait                 = true
  depends_on = [
    talos_machine_bootstrap.bootstrap
  ]
}

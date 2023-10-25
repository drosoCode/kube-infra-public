resource "proxmox_vm_qemu" "vm" {
  for_each = {
    for index, vm in var.nodes :
    vm.hostname => vm
  }

  desc        = "[TF] [${var.cluster.name}] ${each.value.hostname}"
  name        = each.value.hostname
  target_node = each.value.pm_node
  cpu         = "host,flags=+aes"
  cores       = each.value.cores
  sockets     = 1
  onboot      = true
  numa        = true
  hotplug     = "network,disk,usb"
  memory      = each.value.memory
  balloon     = each.value.balloon
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"
  machine     = "q35"

  os_type                 = "cloud_init"
  clone                   = each.value.cloud_init_image
  cloudinit_cdrom_storage = each.value.cloud_init_storage
  ipconfig0               = "ip=${each.value.address}/${var.networking.mask},gw=${var.networking.gateway}"
  nameserver              = join(" ", var.networking.nameservers)

  disk {
    size    = each.value.disk_size
    storage = each.value.storage_pool
    type    = "scsi"
  }

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # https://github.com/Telmate/terraform-provider-proxmox/issues/299
  dynamic "hostpci" {
    for_each = each.value.pci
    content {
      host   = hostpci.value
      rombar = 1
      pcie   = 0
    }
  }

  dynamic "usb" {
    for_each = each.value.usb
    content {
      host = usb.value
    }
  }

  lifecycle {
    ignore_changes = [
      boot,
      bootdisk,
      qemu_os,
      network,
      desc,
      numa,
      agent,
      ipconfig0,
      ipconfig1,
      define_connection_info,
      machine
    ]
  }
}

data "talos_machine_configuration" "vm_talos" {
  for_each = {
    for index, vm in var.nodes :
    vm.hostname => vm
  }

  cluster_name     = var.cluster.name
  cluster_endpoint = var.cluster.endpoint
  machine_type     = each.value.controlplane ? "controlplane" : "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches = [
    each.value.controlplane ?
    yamlencode({ # if controlplane
      machine = {
        certSANs = var.cluster.extra_san
      }
      cluster = {
        allowSchedulingOnControlPlanes = var.cluster.allow_scheduling_on_control_planes
        apiServer = {
          admissionControl = [
            {
              name = "PodSecurity"
              configuration = {
                apiVersion= "pod-security.admission.config.k8s.io/v1alpha1"
                kind = "PodSecurityConfiguration"
                defaults = {
                  audit = "restricted"
                  audit-version = "latest"
                  enforce = "baseline"
                  enforce-version = "latest"
                  warn = "restricted"
                  warn-version = "latest"
                }
                exemptions = {
                  namespaces = ["cilium-system"] # kube-system already included
                  runtimeClasses = ["nvidia"]
                  usernames = []
                }
              }
            }
          ]
          extraArgs = {
            oidc-issuer-url = "https://auth.REDACTED",
            oidc-client-id = "kubernetes",
            oidc-username-claim = "preferred_username",
            oidc-groups-claim = "groups",
            oidc-groups-prefix = "oidc-",
            oidc-signing-algs = "RS256"
          }
        }
        network = {
          cni = {
            name = "none" # disable flannel
          }
        }
        proxy = {
          disabled = true # disable kube proxy
        }
        inlineManifests = [
          {
            name     = "cilium"
            contents = local.cilium_manifest
          }
        ]
      }
    }) : null,   # if worker
    yamlencode({ # common to worker and controlplane
      machine = {
        kubelet = {
          nodeIP = {
            validSubnets = var.cluster.valid_subnets
          }
        }
        time = {
          servers = var.cluster.time_servers
        }
        network = {
          hostname = each.value.hostname
        }
        sysctls = {
          "vm.max_map_count" = 262144
        }
      }
    }),
    each.value.gpu ? # if gpu
    yamlencode({
      machine = {
        kernel = {
          modules = [
            { name = "nvidia" },
            { name = "nvidia_uvm" },
            { name = "nvidia_drm" },
            { name = "nvidia_modeset" },
          ]
        }
        sysctls = {
          "net.core.bpf_jit_harden" = 1
        }
      }
    }) : null
  ]
}

resource "talos_machine_configuration_apply" "vm_talos_apply" {
  for_each = {
    for index, vm in var.nodes :
    vm.hostname => vm
  }

  depends_on = [
    talos_machine_secrets.this,
    proxmox_vm_qemu.vm
  ]

  client_configuration        = talos_machine_secrets.this.client_configuration
  node                        = each.value.address
  machine_configuration_input = data.talos_machine_configuration.vm_talos[each.value.hostname].machine_configuration
}

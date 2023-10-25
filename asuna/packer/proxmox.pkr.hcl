packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "talos" {
  proxmox_url              = var.pm_url
  username                 = var.pm_user
  password                 = var.pm_password
  node                     = var.pm_node_name
  insecure_skip_tls_verify = true
  iso_download_pve         = true

  #iso_file    = var.iso_file
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  scsi_controller = "virtio-scsi-pci"
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  disks {
    type         = "scsi"
    storage_pool = var.pm_storage
    format       = "raw"
    disk_size    = "10G"
    cache_mode   = "writethrough"
  }

  memory       = 2048
  ssh_username = "root"
  ssh_password = "packer"
  ssh_timeout  = "15m"
  qemu_agent   = true

  boot_wait = "60s"
  boot_command = [
    "passwd<enter><wait>packer<enter><wait>packer<enter>",
    "ip address add ${var.static_ip} broadcast + dev ens18<enter><wait>",
    "ip route add 0.0.0.0/0 via ${var.gateway} dev ens18<enter><wait>"
  ]
}

build {
  name = "release"

  source "source.proxmox-iso.talos" {
    template_name        = "talos-init"
    template_description = "Talos system disk"
  }

  provisioner "shell" {
    inline = [
      "curl -L ${local.image} -o /tmp/talos.raw.xz",
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
    ]
  }
}

build {
  name = "release-nvidia"

  source "source.proxmox-iso.talos" {
    template_name        = "talos-nvidia-init"
    template_description = "Talos system disk with nvidia drivers"
  }

  provisioner "file" {
    source = "../talos-nvidia/out/nocloud-amd64.raw.xz"
    destination = "/tmp/talos.raw.xz"
  }

  provisioner "shell" {
    inline = [
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
    ]
  }
}

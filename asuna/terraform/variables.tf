variable "proxmox" {
  type = object({
    api_url   = string
    node_name = string
    username  = string
  })
}

variable "controlplane_address" {
  type = string
}

variable "pm_password" {
  type      = string
  sensitive = true
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "cluster" {
  type = object({
    name                               = string
    cilium_version                     = string
    endpoint                           = string
    service_host                       = string
    service_port                       = string
    allow_scheduling_on_control_planes = bool
    valid_subnets                      = list(string)
    time_servers                       = list(string)
    extra_san                          = list(string)
  })
}

variable "networking" {
  type = object({
    gateway     = string
    nameservers = list(string)
    mask        = string
  })
}

variable "nodes" {
  type = list(object({
    // required
    controlplane = bool
    hostname     = string
    pm_node      = string
    address      = string
    // default
    cloud_init_image   = optional(string, "talos-init")
    cloud_init_storage = optional(string, "HDD3")
    disk_size          = optional(string, "50G")
    storage_pool       = optional(string, "HDD3")
    cores              = optional(number, 4)
    memory             = optional(number, 16384)
    balloon            = optional(number, 16384)
    pci                = optional(list(string), [])
    usb                = optional(list(string), [])
    gpu                = optional(bool, false)
  }))
}

variable "flux" {
  type = object({
    github_org       = string
    github_repo      = string
    github_branch    = string
    flux_path        = string
    sops_secret_name = string
    sops_key_path    = string
    version          = string
  })
}

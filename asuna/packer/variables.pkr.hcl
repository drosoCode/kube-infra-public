variable "pm_user" {
  type = string
  default = "root@pam"
}

variable "pm_password" {
  type = string
  sensitive = true
}

variable "pm_url" {
  type = string
  default = "https://10.10.2.4:8006/api2/json"
}

variable "pm_node_name" {
  type = string
  default = "asuna"
}

variable "pm_storage" {
  type = string
  default = "local-lvm"
}

variable "static_ip" {
  type = string
  default = "10.10.100.1/16"
}

variable "gateway" {
  type = string
  default = "10.10.1.1"
}

variable "iso_url" {
    type = string
    default = "http://archlinux.mirrors.ovh.net/archlinux/iso/2023.06.01/archlinux-2023.06.01-x86_64.iso"
}

variable "iso_checksum" {
  type = string
  default = "def774822f77da03b12ed35704e48f35ce61d60101071151a6d221994e0b567e"
}

variable "iso_storage_pool" {
  type = string
  default = "local"
}

variable "talos_version" {
  type    = string
  default = "v1.4.6"
}

locals {
  image = "https://github.com/talos-systems/talos/releases/download/${var.talos_version}/nocloud-amd64.raw.xz"
}
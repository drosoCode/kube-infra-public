flux = {
  version          = "v2.1.0"
  flux_path        = "./k8s/cluster"
  github_org       = "drosocode"
  github_repo      = "kube-infra"
  github_branch    = "main"
  sops_secret_name = "kube-infra-sops-age"
  sops_key_path    = "../../keys.txt"
}

proxmox = {
  api_url   = "https://10.10.2.4:8006/api2/json"
  node_name = "asuna"
  username  = "root@pam"
}

cluster = {
  name                               = "mina"
  endpoint                           = "https://10.10.100.41:6443"
  service_host                       = "10.10.100.41"
  service_port                       = 6443
  allow_scheduling_on_control_planes = true
  valid_subnets                      = ["10.5.0.0/16"]
  time_servers                       = ["pool.ntp.org", "time.cloudflare.com"]
  extra_san                          = ["cluster.REDACTED.net"]
  cilium_version                     = "v1.14.0"
}

networking = {
  gateway     = "10.10.1.1"
  nameservers = ["10.10.1.1"]
  mask        = "16"
}

nodes = [{
  hostname     = "k8smaster"
  controlplane = true
  pm_node      = "asuna"
  address      = "10.10.100.41"
  usb          = ["0451:bef3"] # ti zigbee
  }, {
  hostname         = "k8snode1"
  controlplane     = false
  pm_node          = "asuna"
  address          = "10.10.100.42"
  cloud_init_image = "talos-nvidia-init"
  gpu              = true
  pci              = ["0000:01:00.0", "0000:01:00.1"] # 1050ti
}]

controlplane_address = "10.10.100.41"

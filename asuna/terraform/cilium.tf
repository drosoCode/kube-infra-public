data "helm_template" "cilium" {
  name         = "cilium"
  namespace    = "cilium-system"
  repository   = "https://helm.cilium.io/"
  chart        = "cilium"
  version      = var.cluster.cilium_version
  include_crds = true

  values = [
    yamlencode({
      ipam = {
        mode = "kubernetes"
      }

      # kube proxy replacement
      kubeProxyReplacement = "strict"
      k8sServiceHost       = var.cluster.service_host
      k8sServicePort       = var.cluster.service_port

      # L2 annoucements / LB
      #l2announcements = {
      #  enabled = true
      #  leaseDuration = "60s"
      #  leaseRenewDeadline = "100s"
      #  leaseRetryPeriod = "5s"
      #}
      #k8sClientRateLimit = {
      #  qps = 5
      #  burst = 8
      #}

      # Talos run recent kernel
      enableXTSocketFallback = false

      # Talos specific
      # https://www.talos.dev/v1.4/kubernetes-guides/network/deploying-cilium/#method-2-helm-manifests-install
      securityContext = {
        capabilities = {
          ciliumAgent = [
            "CHOWN",
            "DAC_OVERRIDE",
            "FOWNER",
            "IPC_LOCK",
            "KILL",
            "NET_ADMIN",
            "NET_RAW",
            "SETGID",
            "SETUID",
            "SYS_ADMIN",
            "SYS_RESOURCE",
          ]
          cleanCiliumState = [
            "NET_ADMIN",
            "SYS_ADMIN",
            "SYS_RESOURCE",
          ]
        }
      }
      cgroup = {
        autoMount = { enabled = false }
        hostRoot  = "/sys/fs/cgroup"
      }
      hubble = {
        enabled = true
        metrics = {
          enabled = [
            "dns",
            "drop",
            "port-distribution",
            "icmp",
            "httpV2"
          ]
          enableOpenMetrics = true
        }
        relay = {
          enabled = true
        }
        ui = {
          enabled = true
        }
      }
      prometheus = {
        enabled = true 
      }
    })
  ]
}

locals {
  cilium_manifest = join("\n---\n", [
    yamlencode({
      apiVersion = "v1"
      kind       = "Namespace"
      metadata = {
        name = "cilium-system"
      }
    }),
    data.helm_template.cilium.manifest,
    #yamlencode({
    #  apiVersion = "cilium.io/v2alpha1"
    #  kind = "CiliumLoadBalancerIPPool"
    #  metadata = {
    #    name = "cilium-ipam-lb"
    #    namespace = "cilium-system"
    #  }
    #  spec = {
    #    cidrs = [
    #      {
    #        cidr = "10.10.100.1/32"
    #      }
    #    ]
    #    disabled = false
    #    # serviceSelector = {
    #    #   matchLabels = {
    #    #     "app.kubernetes.io/name" = "traefik"
    #    #   }
    #    # }
    #  }
    #})
  ])
}

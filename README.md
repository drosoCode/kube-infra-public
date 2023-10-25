# Kube Infra

Homelab based on Kubernetes

- Router: [OPNsense](https://opnsense.org/)
- Hypervisor: [Proxmox](https://www.proxmox.com/en/)
- Storage Server: [Debian](https://www.debian.org) + [Snapraid](https://www.snapraid.it/)/[MergerFS](https://github.com/trapexit/mergerfs)
- K8s Distribution: [Talos](https://www.talos.dev/)
- Load Balancer: [Metallb](https://metallb.universe.tf/)
- Ingress Controller: [Traefik](https://traefik.io/traefik/)
- GitOps Toolkit: [Flux CD](https://fluxcd.io/)
- Infra Tools: [Packer](https://www.packer.io/), [Terraform](https://www.terraform.io/), [Ansible](https://www.ansible.com/)
- Secrets Management: [SOPS](https://github.com/getsops/sops)

## Installation

Install the local tools 
`yay -S flux-bin sops age terraform packer talosctl crane cilium-cli hubble-bin k9s ansible`

Configure git hooks `git config core.hooksPath scripts/hooks`


### Configuring Storage Server

To install and configure all the required packages for the storage server, go into `kirito/ansible` and run

`ansible-galaxy collection install community.sops`

`ansible-playbook -i inventory ./install.yaml`

### Building Cloud Init Images

To generate the cloud-init images for proxmox, go in `asuna/packer` and run

`packer init -upgrade .`

`packer build -var pm_password="" -force .`

You can also restrict the build to a specific image (ex: `-only=release.proxmox-iso.talos` to skip nvidia image build)

#### Nvidia specific

Make sure that you have docker and crane installed.

You may need to edit your daemon configuration to add these features:

```json
{
  "features": {
    "containerd-snapshotter": true
  },
  "experimental": true
}
```
To generate nvidia custom disk image (used by packer), run `cd asuna/talos-nvidia && ./build.sh`


### Deploying Cluster

To create the VMs, install talos and bootstrap the cluster with flux, go in `asuna/terraform` and run:

`terraform init`

`terraform apply`

You can get the kubeconfig file with `terraform output -raw kubeconfig > ~/.kube/config`

terraform {
  required_version = "= 1.15.1"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "= 2.5.3"
    }

    proxmox = {
      source  = "bpg/proxmox"
      version = "= 0.105.0"
    }
  }
}

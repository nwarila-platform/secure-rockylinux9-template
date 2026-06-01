variable "proxmox_endpoint" {
  description = "Optional Proxmox VE API endpoint override. When null, bpg/proxmox reads PROXMOX_VE_ENDPOINT."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.proxmox_endpoint == null || can(regex("^https://[^[:space:]]+$", var.proxmox_endpoint))
    error_message = "proxmox_endpoint must be null or an https:// URL."
  }
}

variable "proxmox_api_token" {
  description = "Optional Proxmox VE API token override. When null, bpg/proxmox reads PROXMOX_VE_API_TOKEN."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Allow the Proxmox provider to skip TLS verification for lab endpoints."
  type        = bool
  default     = false
  nullable    = false
}

variable "family" {
  description = "Template family discriminator echoed by the ISO manager module."
  type        = string
  default     = "rocky9"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9._-]+$", var.family))
    error_message = "family must consist of lowercase letters, digits, hyphens, dots, and underscores only."
  }
}

variable "iso_pin" {
  description = "Exact Rocky ISO pin consumed by terraform-proxmox-iso-manager-framework."
  type = object({
    url      = string
    sha256   = string
    filename = string
  })
  nullable = false

  validation {
    condition     = can(regex("^https://[A-Za-z0-9.-]+(:[0-9]{1,5})?/[^\\s?#]+$", var.iso_pin.url))
    error_message = "iso_pin.url must be a non-tokenized https:// URL with a host and path."
  }

  validation {
    condition     = can(regex("^[0-9a-f]{64}$", var.iso_pin.sha256))
    error_message = "iso_pin.sha256 must be a 64-character lowercase hex SHA-256 digest."
  }

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+\\.iso$", var.iso_pin.filename))
    error_message = "iso_pin.filename must be a simple filename ending in .iso."
  }
}

variable "node" {
  description = "Proxmox node that performs the server-side ISO download."
  type        = string
  default     = "tcnhq-prxmx01"
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.node))
    error_message = "node must consist of letters, digits, hyphens, dots, and underscores only."
  }
}

variable "storage" {
  description = "Proxmox storage datastore with ISO content type enabled."
  type        = string
  default     = "cephFS"
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.storage))
    error_message = "storage must consist of letters, digits, hyphens, dots, and underscores only."
  }
}

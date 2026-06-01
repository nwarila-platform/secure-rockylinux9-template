module "iso" {
  source = "git::https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework.git//terraform?ref=v1.2.0"

  family  = var.family
  iso_pin = var.iso_pin
  node    = var.node
  storage = var.storage
}

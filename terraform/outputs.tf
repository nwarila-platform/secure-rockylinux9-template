output "iso_path" {
  description = "Storage-prefixed ISO path consumable by Packer's proxmox-iso plugin."
  value       = module.iso.iso_path
}

output "iso_sha256" {
  description = "SHA-256 digest of the managed ISO."
  value       = module.iso.iso_sha256
}

output "iso_id" {
  description = "Proxmox file ID for the managed ISO."
  value       = module.iso.iso_id
}

output "iso_url" {
  description = "Non-tokenized upstream ISO URL."
  value       = module.iso.iso_url
}

output "family" {
  description = "Template family discriminator."
  value       = module.iso.family
}

output "node" {
  description = "Proxmox node where the ISO download is performed."
  value       = module.iso.node
}

output "storage" {
  description = "Proxmox storage datastore where the ISO is managed."
  value       = module.iso.storage
}

resource "local_file" "packer_boot_iso_vars" {
  filename        = "${path.module}/iso-manager.auto.pkrvars.hcl"
  file_permission = "0644"
  content         = <<-EOT
boot_iso = {
  cd_label             = "BOOTISO"
  iso_checksum         = "sha256:${module.iso.iso_sha256}"
  iso_file             = "${module.iso.iso_path}"
  iso_urls             = null
  index                = 0
  iso_download_pve     = null
  iso_storage_pool     = null
  iso_target_extension = null
  iso_target_path      = null
  keep_cdrom_device    = false
  type                 = "scsi"
  unmount              = true
}
EOT
}

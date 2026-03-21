# ============================================================================================= #
# Rocky Linux 9 — UEFI, VirtIO, SSH communicator, DISA STIG Kickstart                         #
#                                                                                               #
# Consumer configuration for the Proxmox-Packer-Framework.                                     #
# See: https://github.com/NWarila/Proxmox-Packer-Framework/blob/main/docs/template-contract.md #
# ============================================================================================= #
packer_image = {

  # Proxmox Settings
  insecure_skip_tls_verify = true

  # Connection Settings
  communicator                 = "ssh"
  ssh_timeout                  = "30m"
  winrm_timeout                = null
  winrm_port                   = null
  winrm_use_ssl                = null
  winrm_insecure               = null
  winrm_use_ntlm               = null
  winrm_transport              = null
  winrm_server_cert_validation = null

  # Template Metadata
  os_language = "en_US"
  os_keyboard = "us"
  os_timezone = "UTC"
  os_family   = "linux"
  os_name     = "rocky"
  os_version  = "9"

  # General Settings
  template_description = "Rocky Linux 9 Template built with Packer"
  template_name        = "rocky-linux-9-template"
  vm_id                = 9000
  pool                 = "tmpl-golden-pkr"
  node                 = "tcnhq-prxmx01"
  vm_name              = "rocky-linux-9-template"
  tags                 = ["rocky", "linux", "template", "packer"]

  # QEMU Agent
  qemu_agent           = true
  qemu_additional_args = ""

  # Misc Settings
  disable_kvm  = false
  machine      = "q35"
  os           = "l26"
  task_timeout = "10m"

  # VM Configuration: Boot Settings
  bios                   = "ovmf"
  boot                   = "order=scsi2;scsi0;scsi1;"
  boot_key_interval      = null
  boot_keygroup_interval = null
  boot_wait              = "10s"
  onboot                 = false
  boot_command = [
    "<up>",
    "e",
    "<down><down><end><wait>",
    " inst.text inst.ks=hd:LABEL=OEMDRV:/ks.cfg",
    "<leftCtrlOn>x<leftCtrlOff>"
  ]

  # VM Configuration: Cloud-Init
  cloud_init              = true
  cloud_init_disk_type    = "scsi"
  cloud_init_storage_pool = "nvme-pool"

  # Hardware: CPU
  cores    = 2
  cpu_type = "host"
  sockets  = 1

  # Hardware: Memory
  ballooning_minimum = 0
  memory             = 4096
  numa               = false

  # Hardware: Misc
  scsi_controller = "virtio-scsi-single"
  serials         = []
  vm_interface    = null

}

# --- Install Template -------------------------------------------------------------------- #
# Points to the consumer-owned Kickstart template. The framework renders this template with
# the guaranteed template variable contract and packages it onto a virtual CD.
# See: docs/template-contract.md in the framework repository.
install_template = {
  template_path    = "./ks.pkrtpl.hcl"
  output_file      = "/ks.cfg"
  cd_label         = "OEMDRV"
  cd_type          = "scsi"
  iso_storage_pool = "cephFS"
  extra_cd_content = {}
}

# --- Ansible Configuration --------------------------------------------------------------- #
# Consumer-owned Ansible provisioner configuration. The framework handles connection wiring
# (SSH/WinRM) automatically; consumer owns playbook content and roles.
# Roles are sourced from: https://github.com/NWarila/ansible-framework
ansible_config = {
  playbook_path     = "./rocky-linux-9.yml"
  requirements_path = null
  roles_path        = "../../ansible-framework"
  config_path       = "../../ansible-framework/ansible.cfg"
  extra_vars        = {}
}

additional_iso_files = []

boot_iso = {
  cd_label             = "BOOTISO"
  iso_checksum         = "sha256:8ff2a47e2f3bfe442617fceb7ef289b7b1d2d0502089dbbd505d5368b2b3a90f"
  iso_file             = "cephFS:iso/Rocky-9.6-x86_64-dvd.iso"
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

disks = [
  {
    asyncio             = "io_uring"
    cache_mode          = "none"
    discard             = false
    exclude_from_backup = false
    format              = "raw"
    io_thread           = false
    size                = "100G"
    ssd                 = true
    storage_pool        = "nvme-pool"
    type                = "scsi"
  }
]

efi_config = {
  efi_format        = "raw"
  efi_storage_pool  = "nvme-pool"
  efi_type          = "4m"
  pre_enrolled_keys = false
}

network_adapters = [
  {
    ipv4_address  = "10.69.128.200"
    ipv4_netmask  = 24
    ipv4_gateway  = "10.69.128.1"
    dns           = ["10.69.128.1"]
    bridge        = "vmbr0"
    firewall      = false
    mac_address   = null
    model         = "virtio"
    mtu           = 1492
    packet_queues = 1
    vlan_tag      = 228
  }
]

pci_devices = []

rng0 = {
  source    = "/dev/urandom"
  max_bytes = 1024
  period    = 1000
}

tpm_config = {
  tpm_storage_pool = "nvme-pool"
  tpm_version      = "v2.0"
}

vga = {
  type   = "virtio"
  memory = null
}

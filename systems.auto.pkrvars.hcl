# ============================================================================================= #
# - File: .\packer.auto.pkvars.hcl                                            | Version: v1.0.0 #
# --- [ Description ] ------------------------------------------------------------------------- #
#                                                                                               #
# ============================================================================================= #
packer_image = {

  # Proxmox Settings
  insecure_skip_tls_verify  = true

  # OS Installation & Configuration
  install_method            = "kickstart"
  additional_packages       = ["python3-dnf"]

  # Template Metadata
  os_language               = "en_US"
  os_keyboard               = "us"
  os_timezone               = "UTC"
  os_family                 = "linux"
  os_name                   = "rocky"
  os_version                = "9"

  # General Settings
  template_description      = "Rocky Linux 9 Template built with Packer"
  template_name             = "rocky-linux-9-template"
  vm_id                     = 9000
  pool                      = "tmpl-golden-pkr"
  node                      = "tcnhq-prxmx01"
  vm_name                   = "rocky-linux-9-template"
  tags                      = ["rocky", "linux", "template", "packer"]

  # QEMU Agent
  qemu_agent                = true
  qemu_additional_args      = ""

  # Misc Settings
  disable_kvm               = false
  machine                   = "q35"
  os                        = "l26"
  task_timeout              = "10m"

  # VM Configuration: Boot Settings
  bios                      = "ovmf"
  boot                      = "order=scsi2;scsi0;scsi1;"
  boot_key_interval         = null
  boot_keygroup_interval    = null
  boot_wait                 = "10s"
  onboot                    = false
  boot_command              = [
    // This sends the "up arrow" key, typically used to navigate through boot menu options.
    "<up>",
    // This sends the "e" key. In the GRUB boot loader, this is used to edit the selected boot menu option.
    "e",
    // This sends two "down arrow" keys, followed by the "end" key, and then waits. This is used to navigate to a specific line in the boot menu option's configuration.
    "<down><down><end><wait>",
    // This types the string "text" followed by the value of the 'data_source_command' local variable.
    // This is used to modify the boot menu option's configuration to boot in text mode and specify the kickstart data source configured in the common variables.
    " inst.text inst.ks=hd:LABEL=OEMDRV:/ks.cfg",
    // This sends the "enter" key, waits, turns on the left control key, sends the "x" key, and then turns off the left control key. This is used to save the changes and exit the boot menu option's configuration, and then continue the boot process.
    "<leftCtrlOn>x<leftCtrlOff>"
  ]

  # VM Configuration: Cloud-Init
  cloud_init                = true
  cloud_init_disk_type      = "scsi"
  cloud_init_storage_pool   = "nvme-pool"

  # Hardware: CPU
  cores                     = 2
  cpu_type                  = "host"
  sockets                   = 1

  # Hardware: Memory
  ballooning_minimum        = 0
  memory                    = 4096
  numa                      = false

  # Hardware: Misc
  scsi_controller           = "virtio-scsi-single"
  serials                   = []
  vm_interface              = null

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
    ipv4_address = "10.69.128.200"
    ipv4_netmask = 24
    ipv4_gateway = "10.69.128.1"
    dns          = ["10.69.128.1"]
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

#region ------ [ Disks & Partitions ] --------------------------------------------------------- #

vm_disk_use_swap   = true
vm_disk_partitions = [
  {
    name = "efi"
    size = 1024,
    format = {
      label  = "EFIFS",
      fstype = "fat32",
    },
    mount = {
      path    = "/boot/efi",
      options = "",
    },
    volume_group = "",
  },
  {
    name = "boot"
    size = 1024,
    format = {
      label  = "BOOTFS",
      fstype = "ext4",
    },
    mount = {
      path    = "/boot",
      options = "",
    },
    volume_group = "",
  },
  {
    name = "sysvg"
    size = -1,
    format = {
      label  = "",
      fstype = "",
    },
    mount = {
      path    = "",
      options = "",
    },
    volume_group = "sysvg",
  },
]
vm_disk_lvm = [
  {
    name: "sysvg",
    partitions: [
      {
        name = "lv_swap",
        size = 1024,
        format = {
          label  = "SWAPFS",
          fstype = "swap",
        },
        mount = {
          path    = "",
          options = "",
        },
      },
      {
        name = "lv_root",
        size = 10240,
        format = {
          label  = "ROOTFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/",
          options = "",
        },
      },
      {
        name = "lv_home",
        size = 4096,
        format = {
          label  = "HOMEFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/home",
          options = "nodev,nosuid",
        },
      },
      {
        name = "lv_opt",
        size = 2048,
        format = {
          label  = "OPTFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/opt",
          options = "nodev",
        },
      },
      {
        name = "lv_tmp",
        size = 4096,
        format = {
          label  = "TMPFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/tmp",
          options = "nodev,noexec,nosuid",
        },
      },
      {
        name = "lv_var",
        size = 2048,
        format = {
          label  = "VARFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/var",
          options = "nodev",
        },
      },
      {
        name = "lv_var_tmp",
        size = 1000,
        format = {
          label  = "VARTMPFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/var/tmp",
          options = "nodev,noexec,nosuid",
        },
      },
      {
        name = "lv_var_log",
        size = 4096,
        format = {
          label  = "VARLOGFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/var/log",
          options = "nodev,noexec,nosuid",
        },
      },
      {
        name = "lv_var_audit",
        size = 500,
        format = {
          label  = "AUDITFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/var/log/audit",
          options = "nodev,noexec,nosuid",
        },
      },
    ],
  }
]


#endregion --- [ Disks & Partitions ] --------------------------------------------------------- #


### Installs from the first attached CD-ROM/DVD on the system.
cdrom

### Performs the kickstart installation in text mode.
### By default, kickstart installations are performed in graphical mode.
text

### Accepts the End User License Agreement.
eula --agreed

### Sets the language to use during installation and the default language to use on the installed system.
lang ${os_language}

### Sets the default keyboard type for the system.
keyboard ${os_keyboard}

### Configure network information for target system and activate network devices in the installer environment (optional)
### --onboot	  enable device at a boot time
### --device	  device to be activated and / or configured with the network command
### --bootproto	  method to obtain networking configuration for device (default dhcp)
### --noipv6	  disable IPv6 on this device
%{ if network_ipv4_address != null ~}
network --activate --bootproto=static --device=${network_device} --gateway=${network_ipv4_gateway} --ip=${network_ipv4_address} --nameserver=${join(",", network_dns)} --netmask=${cidrnetmask("${network_ipv4_address}/${network_ipv4_netmask}")} --noipv6 --onboot=yes
%{ else ~}
network --bootproto=dhcp --device=${network_device}
%{ endif ~}

### Lock the root account.
rootpw --lock

# Configure firewall settings for the system (optional)
# --enabled	reject incoming connections that are not in response to outbound requests
# --ssh		allow sshd service through the firewall
firewall --enabled --ssh

# State of SELinux on the installed system (optional)
# Defaults to enforcing
selinux --enforcing

# Set the system time zone (required)
timezone ${os_timezone}

#region ------ [ Storage Configuration ] ------------------------------------------------------ #
### Sets how the boot loader should be installed.
%{ if build_bios == "ovmf" ~}
bootloader --append="crashkernel=no"
%{ else ~}
bootloader --location=mbr
%{ endif ~}

### Initialize any invalid partition tables found on disks.
zerombr

### Restrict installation and partition wiping to the primary SCSI boot disk used by this template.
ignoredisk --only-use=sda

### Removes partitions from the system, prior to creation of new partitions.
### By default, no partitions are removed.
### --all	Erases all partitions from the system
### --initlabel Initializes a disk (or disks) by creating a default disk label for all disks in their respective architecture.
clearpart --all --drives=sda --initlabel

### Storage layout is intentionally fixed in this template rather than variablized via pkrvars.
### Create primary system partitions.
part /boot/efi --label=EFIFS --fstype=vfat --fsoptions="nodev,nosuid" --size=1024
part /boot --label=BOOTFS --fstype=ext4 --fsoptions="nodev,nosuid" --size=1024
part pv.sysvg --size=100 --grow

### Create a logical volume management (LVM) group.
volgroup sysvg pv.sysvg

### Create logical volumes.
logvol swap --name=lv_swap --vgname=sysvg --label=SWAPFS --fstype=swap --size=1024
logvol / --name=lv_root --vgname=sysvg --label=ROOTFS --fstype=ext4 --size=10240
logvol /home --name=lv_home --vgname=sysvg --label=HOMEFS --fstype=ext4 --fsoptions="nodev,nosuid,noexec" --size=4096
logvol /opt --name=lv_opt --vgname=sysvg --label=OPTFS --fstype=ext4 --fsoptions="nodev" --size=2048
logvol /tmp --name=lv_tmp --vgname=sysvg --label=TMPFS --fstype=ext4 --fsoptions="nodev,noexec,nosuid" --size=4096
logvol /var --name=lv_var --vgname=sysvg --label=VARFS --fstype=ext4 --fsoptions="nodev" --size=2048
logvol /var/tmp --name=lv_var_tmp --vgname=sysvg --label=VARTMPFS --fstype=ext4 --fsoptions="nodev,noexec,nosuid" --size=1000
logvol /var/log --name=lv_var_log --vgname=sysvg --label=VARLOGFS --fstype=ext4 --fsoptions="nodev,noexec,nosuid" --size=4096
logvol /var/log/audit --name=lv_var_audit --vgname=sysvg --label=AUDITFS --fstype=ext4 --fsoptions="nodev,noexec,nosuid" --size=500

### Do not configure X on the installed system.
skipx

### Install Core Package(s)
%packages --ignoremissing --excludedocs --exclude-weakdeps --inst-langs=en_US
  @^minimal-environment
  -iwl*firmware
  qemu-guest-agent
%end

### Modifies the default set of services that will run under the default runlevel.
services --enabled=NetworkManager,sshd,qemu-guest-agent

### Apply DISA STIG during install via OpenSCAP add-on
%addon com_redhat_oscap
  content-type = scap-security-guide
  profile = xccdf_org.ssgproject.content_profile_stig
%end

### Create the SSH access control group before creating the deploy user.
group --name=ssh-users

# Create the deploy user
user --name=${deploy_user_name} --plaintext --password=${deploy_user_password} --groups=wheel,ssh-users
sshkey --username=${deploy_user_name} "${deploy_user_public_key}"

### Post-installation commands.
%post --erroronfail --log=/root/ks-post.log

  # TODO: Move these SSH settings into an sshd_config.d drop-in once the bootstrap flow is ready.
  # Configure the SSH Service To Allow SSH After System Hardening
  sed -ri 's/^#?PermitRootLogin.*/PermitRootLogin no/'               /etc/ssh/sshd_config
  sed -i 's#^[#[:space:]]*Subsystem[[:space:]]\\+sftp.*#Subsystem sftp /usr/libexec/openssh/sftp-server#' /etc/ssh/sshd_config \
    || echo 'Subsystem sftp /usr/libexec/openssh/sftp-server' | tee -a /etc/ssh/sshd_config
  echo "AllowGroups ssh-users"                                    >> /etc/ssh/sshd_config

  # Configure the deploy user
  chage -m 1 -M 60 -W 14 -d $(date +%F) ${deploy_user_name}

%end

# Reboot after the installation is complete (optional)
# --eject	attempt to eject CD or DVD media before rebooting
reboot --eject

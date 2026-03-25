# ------------------------------------------------------------------------------------------------ #
# Installation Source and Locale                                                                   #
# ------------------------------------------------------------------------------------------------ #
cdrom
text
eula --agreed

lang ${os_language}
keyboard ${os_keyboard}
timezone ${os_timezone}

# ------------------------------------------------------------------------------------------------ #
# Networking and Base Security                                                                     #
# ------------------------------------------------------------------------------------------------ #
%{ if network_ipv4_address != null ~}
network --activate --bootproto=static --device=${network_device} --gateway=${network_ipv4_gateway} --ip=${network_ipv4_address} --nameserver=${join(",", network_dns)} --netmask=${cidrnetmask("${network_ipv4_address}/${network_ipv4_netmask}")} --noipv6 --onboot=yes
%{ else ~}
network --bootproto=dhcp --device=${network_device}
%{ endif ~}

rootpw --lock
firewall --enabled --ssh
selinux --enforcing

# ------------------------------------------------------------------------------------------------ #
# Bootloader and Disk Selection                                                                    #
# ------------------------------------------------------------------------------------------------ #
%{ if build_bios == "ovmf" ~}
bootloader --append="crashkernel=no"
%{ else ~}
bootloader --location=mbr
%{ endif ~}

zerombr
ignoredisk --only-use=sda
clearpart --all --drives=sda --initlabel

# ------------------------------------------------------------------------------------------------ #
# Fixed Storage Layout                                                                             #
# ------------------------------------------------------------------------------------------------ #
part /boot/efi --label=EFIFS --fstype=vfat --fsoptions="nodev,nosuid" --size=1024
part /boot --label=BOOTFS --fstype=ext4 --fsoptions="nodev,nosuid" --size=1024
part pv.sysvg --size=100 --grow

volgroup sysvg pv.sysvg

logvol swap           --name=lv_swap      --vgname=sysvg --label=SWAPFS   --fstype=swap --size=1024
logvol /              --name=lv_root      --vgname=sysvg --label=ROOTFS   --fstype=ext4 --size=10240
logvol /home          --name=lv_home      --vgname=sysvg --label=HOMEFS   --fstype=ext4 --fsoptions="nodev,nosuid,noexec" --size=4096
logvol /opt           --name=lv_opt       --vgname=sysvg --label=OPTFS    --fstype=ext4 --fsoptions="nodev" --size=2048
logvol /tmp           --name=lv_tmp       --vgname=sysvg --label=TMPFS    --fstype=ext4 --fsoptions="nodev,noexec,nosuid" --size=4096
logvol /var           --name=lv_var       --vgname=sysvg --label=VARFS    --fstype=ext4 --fsoptions="nodev,nosuid" --size=2048
logvol /var/tmp       --name=lv_var_tmp   --vgname=sysvg --label=VARTMPFS --fstype=ext4 --fsoptions="nodev,noexec,nosuid" --size=1000
logvol /var/log       --name=lv_var_log   --vgname=sysvg --label=VARLOGFS --fstype=ext4 --fsoptions="nodev,noexec,nosuid" --size=4096
logvol /var/log/audit --name=lv_var_audit --vgname=sysvg --label=AUDITFS  --fstype=ext4 --fsoptions="nodev,noexec,nosuid" --size=500

# ------------------------------------------------------------------------------------------------ #
# Packages, Services, and Baseline Policy                                                         #
# ------------------------------------------------------------------------------------------------ #
skipx

%packages --ignoremissing --excludedocs --exclude-weakdeps --inst-langs=en_US
  @^minimal-environment
  -iwl*firmware
  cloud-init
  qemu-guest-agent
%end

services --enabled=NetworkManager,sshd,qemu-guest-agent,cloud-init,cloud-config,cloud-final,cloud-init-local

%addon com_redhat_oscap
  content-type = scap-security-guide
  profile = xccdf_org.ssgproject.content_profile_stig
%end

# -------------------------------------------------------------------------------------------- #
# Identity and Access                                                                           #
# ------------------------------------------------------------------------------------------------ #
group --name=ssh-users

user --name=${deploy_user_name} --iscrypted --password=${deploy_user_password_hash} --groups=wheel,ssh-users
sshkey --username=${deploy_user_name} "${deploy_user_key}"

# ------------------------------------------------------------------------------------------------ #
# Post-Install Hardening and Compatibility                                                         #
# ------------------------------------------------------------------------------------------------ #
%post --erroronfail --log=/root/ks-post.log

  # Normalize SFTP to the Rocky 9 path and keep a compatibility symlink
  # for tooling that still probes /usr/lib/sftp-server.
  if [ -d /etc/ssh/sshd_config.d ]; then
    find /etc/ssh/sshd_config.d -maxdepth 1 -type f -name '*.conf' -exec \
      sed -i '/^[#[:space:]]*Subsystem[[:space:]]\+sftp[[:space:]].*/d' {} +
  fi
  sed -i '/^[#[:space:]]*Subsystem[[:space:]]\+sftp[[:space:]].*/d' /etc/ssh/sshd_config
  echo "Subsystem sftp /usr/libexec/openssh/sftp-server" >> /etc/ssh/sshd_config
  install -d -m 0755 /etc/ssh/sshd_config.d
  cat > /etc/ssh/sshd_config.d/50-build-access.conf <<'EOF'
AllowGroups ssh-users
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
EOF
  ln -sfn /usr/libexec/openssh/sftp-server /usr/lib/sftp-server
  restorecon -Rv /etc/ssh/sshd_config.d || true
  restorecon -v /usr/lib/sftp-server /usr/libexec/openssh/sftp-server /etc/ssh/sshd_config || true

  sshd -t

  chage -m 1 -M 60 -W 14 -d $(date +%F) ${deploy_user_name}

%end

reboot --eject

# STIG Hardening via Kickstart

This repository's Rocky Linux 9 hardening baseline is applied during
installation. The source of truth is `packer/ks.pkrtpl.hcl`, not the Ansible
playbook.

## What Applies the STIG Profile

The Kickstart template enables the Anaconda OpenSCAP add-on:

```text
%addon com_redhat_oscap
  content-type = scap-security-guide
  profile = xccdf_org.ssgproject.content_profile_stig
%end
```

That means the DISA STIG profile is applied while the OS is installed, using
the SCAP Security Guide content available to the Rocky installer. This is the
right phase for controls that affect partitioning, early package selection,
SELinux state, firewalld, and first-boot access posture.

## Repo-Owned Install Controls

The same Kickstart file also owns the repo-specific install baseline:

- locked root account;
- SELinux enforcing;
- firewalld enabled with SSH allowed;
- fixed LVM layout with separate `/home`, `/tmp`, `/var`, `/var/tmp`,
  `/var/log`, and `/var/log/audit`;
- mount options such as `nodev`, `nosuid`, and `noexec` where appropriate;
- minimal package set with weak dependencies and docs excluded;
- deploy-user creation from runtime-generated credentials;
- SSH public-key bootstrap for the deploy user; and
- post-install SSH hardening and SFTP subsystem normalization.

These controls are committed inputs. The runtime credential material is not:
`secure-packer-bootstrapper` generates the deploy password, password hash, and
SSH key immediately before validation/build.

## What Ansible Does Today

`packer/rocky-linux-9.yml` is currently a bootstrap entrypoint. It normalizes
SSH/SFTP behavior so the Packer Ansible provisioner can connect reliably, probes
the remote temporary directory, resets the SSH connection, and gathers facts.
Its `roles: []` list is intentional at the current pinned upstream state.

Reusable Rocky Linux 9 hardening roles are still upstream work in
`ansible-framework`. The absence of a local role invocation here is not the
source of the current STIG claim; the claim comes from Kickstart and OpenSCAP
at install time.

## What Is Not Yet Proven

This repository does not yet publish a runtime OpenSCAP compliance score from
the built VM template. It applies the install-time profile and records the
hardening inputs, but it does not claim to provide an SSP, ATO package, or a
post-build compliance attestation.

Future compliance evidence should add an explicit post-build scan path rather
than broadening the current README claim.

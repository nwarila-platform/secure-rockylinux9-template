# Support

## Scope

This repository supports the consumer-owned profile content and repo automation here:

- `packer/systems.auto.pkrvars.hcl`
- `packer/ks.pkrtpl.hcl`
- `packer/rocky-linux-9.yml`
- repository workflows, issue templates, and contributor tooling
- repository documentation and release semantics

## Out of Scope

The following belong elsewhere:

- `proxmox-packer-framework` build logic, plugin contract, or framework normalization behavior
- `ansible-framework` reusable roles, shared Ansible config, or role-loader behavior
- downstream Proxmox runtime operations, VM lifecycle issues, or environment-specific cluster
  administration
- credential issuance, certificate management, or broader secret-management policy
- Rocky Linux distribution bugs or vendor security advisories

## Getting Help

Please include:

- the exact command or workflow you ran
- whether you were using repo-local checks, the framework workspace, or the CI build path
- relevant tool versions (`packer`, `ansible-playbook`, `pre-commit`, Proxmox VE)
- the exact error output and any relevant log snippets

## Where to Ask

- **Bugs in this consumer profile**:
  [bug report template](https://github.com/NWarila/Secure-RockyLinux9-Template/issues/new?template=bug_report.yml)
- **Features in this consumer profile**:
  [feature request template](https://github.com/NWarila/Secure-RockyLinux9-Template/issues/new?template=feature_request.yml)
- **Security issues**: see [SECURITY.md](SECURITY.md)

## Routing Guide

If you are unsure where an issue belongs:

- consumer values, Kickstart content, bootstrap playbook entrypoint, repo docs:
  this repository
- framework-side `packer validate` / `packer build` contract behavior:
  `proxmox-packer-framework`
- reusable Rocky Linux hardening roles or shared Ansible behavior:
  `ansible-framework`

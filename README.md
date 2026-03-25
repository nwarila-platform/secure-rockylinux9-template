# Secure Rocky Linux 9 Template

[![Packer Build](https://github.com/NWarila/Secure-RockyLinux9-Template/actions/workflows/packer.yaml/badge.svg)](https://github.com/NWarila/Secure-RockyLinux9-Template/actions/workflows/packer.yaml)
[![Security Scan](https://github.com/NWarila/Secure-RockyLinux9-Template/actions/workflows/security.yaml/badge.svg)](https://github.com/NWarila/Secure-RockyLinux9-Template/actions/workflows/security.yaml)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A security-hardened Rocky Linux 9 consumer profile for
[Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment/overview). This repository
does not ship standalone `.pkr.hcl` builders. Instead, it owns the consumer inputs under
`packer/` that are copied into
[proxmox-packer-framework](https://github.com/NWarila/proxmox-packer-framework), where the
composed validation and privileged `packer build` steps run. Formatting stays in the repo-local
and PR-gated path instead of the trusted deployment runner. The
tracked Ansible playbook here is the consumer bootstrap entrypoint; reusable Ansible roles remain
upstream in [ansible-framework](https://github.com/NWarila/ansible-framework).

## How This Repo Fits

1. This repository owns the consumer profile inputs:
   `packer/systems.auto.pkrvars.hcl`, `packer/ks.pkrtpl.hcl`, and `packer/rocky-linux-9.yml`.
2. CI checks out `proxmox-packer-framework` and `ansible-framework` at exact SHAs.
3. CI currently applies a repo-owned compatibility overlay to the pinned `proxmox-packer-framework`
   commit until the secure-bootstrap contract is published upstream.
4. CI copies this repo's consumer files into `proxmox-packer-framework/packer`.
5. Packer validation and builds run in the framework checkout, not in this repo alone.

## Validated With

As of March 25, 2026, the composed CI path is pinned to:

| Component | Exact version / pin | Source of truth |
|---|---|---|
| Packer | `1.15.0` | `proxmox-packer-framework/packer/packer.pkr.hcl` |
| `proxmox-packer-framework` | `e218ed935af48de91f17afef4532d88878f101f4` | `.github/workflows/packer.yaml` |
| `ansible-framework` | `e1b52f33d9270b14ba55cdb5810a7a3de0c83b90` | `.github/workflows/packer.yaml` |
| Rocky install media | `Rocky-9.7-x86_64-dvd.iso` | `packer/systems.auto.pkrvars.hcl` |

The pinned `ansible-framework` commit currently publishes `Ansible Core >= 2.17` and
`Python >= 3.12` as its baseline. Rocky Linux 9 reusable hardening roles are still upstream work,
so this repo currently owns the bootstrap playbook entrypoint only.

## Features

| Category | Current state |
|---|---|
| **OS hardening** | CIS-oriented partitioning and mount options in this repo, SELinux enforcing, firewalld enabled, locked root account |
| **Install-time compliance** | DISA STIG profile applied through Kickstart `%addon com_redhat_oscap` |
| **Provisioning** | Consumer-owned Kickstart template and tracked Ansible bootstrap playbook entrypoint; reusable roles remain in `ansible-framework` |
| **Infrastructure** | Proxmox VE template profile via `proxmox-packer-framework`, UEFI/OVMF, Secure Boot, TPM 2.0, template-side Cloud-Init disk |
| **Formatting** | `packer fmt`, `yamllint`, `markdownlint-cli`, `.editorconfig`, VS Code settings |
| **Security** | Trivy, Gitleaks, CodeQL, release-pinned `secure-packer-bootstrapper` runtime credentials, `detect-private-key`, SHA-pinned GitHub Actions |
| **Dependency management** | Dependabot for GitHub Actions and `pre-commit`, plus PR automation for the tracked `secure-packer-bootstrapper` release pin |

## Prerequisites

### Composed Build Contract

| Tool / dependency | Version | Notes |
|---|---|---|
| [Packer](https://developer.hashicorp.com/packer) | `1.15.0` | Exact requirement from the pinned `proxmox-packer-framework` contract |
| [Ansible Core](https://pypi.org/project/ansible-core/) | `2.20.4` recommended | The pinned `ansible-framework` commit currently requires `>= 2.17` |
| Python | `3.12.x` | Required by the current `ansible-framework` / `ansible-core` baseline |
| Rocky ISO | `Rocky-9.7-x86_64-dvd.iso` | SHA256 is pinned in `packer/systems.auto.pkrvars.hcl` |

### Local Contributor Tooling

| Tool / pin | Version | Notes |
|---|---|---|
| [pre-commit](https://pre-commit.com/) | `4.5.1` minimum | Enforced by `.pre-commit-config.yaml` |
| `pre-commit-hooks` | `v6.0.0` | Hook pin in `.pre-commit-config.yaml` |
| [Gitleaks](https://github.com/gitleaks/gitleaks) | `v8.30.1` | Hook pin in `.pre-commit-config.yaml` |
| [yamllint](https://pypi.org/project/yamllint/) | `1.38.0` | Hook pin; VS Code task also expects the CLI locally |
| [markdownlint-cli](https://github.com/igorshubovych/markdownlint-cli) | `v0.48.0` | Hook pin; VS Code task also expects the CLI locally |
| [conventional-pre-commit](https://github.com/compilerla/conventional-pre-commit) | `v4.4.0` | Commit-msg hook pin |

## Getting Started

### 1. Clone This Repo and the Required Sibling Frameworks

```bash
git clone https://github.com/NWarila/Secure-RockyLinux9-Template.git
git clone https://github.com/NWarila/proxmox-packer-framework.git
git clone https://github.com/NWarila/ansible-framework.git
```

The default VS Code tasks and the composed local validation path expect these sibling directories:

```text
../Secure-RockyLinux9-Template
../proxmox-packer-framework
../ansible-framework
```

### 2. Install Pre-Commit Hooks

```bash
pip install pre-commit
pre-commit install --hook-type pre-commit --hook-type pre-push --hook-type commit-msg
```

### 3. Configure GitHub Settings and Runtime Bootstrap Inputs

The settings below are split between static repo-owned inputs and runtime-generated bootstrap
material:

- GitHub repo secrets / variables use the human-facing names in the first column.
- The reviewed `secure-packer-bootstrapper` release pin lives in
  `.github/pins/secure-packer-bootstrapper.env` and is refreshed in pull requests by workflow.
- Local manual Packer runs can either export the exact `PKR_VAR_*` names directly or `eval` the
  `secure-packer-bootstrapper` release bundle in the same shell as `packer validate` /
  `packer build`.

Until the first published `secure-packer-bootstrapper` release exists and PR automation refreshes
the committed pin file, the privileged build intentionally fails closed instead of guessing at a
bundle URL or checksum.

| GitHub setting | Local equivalent | Purpose / precedence |
|---|---|---|
| `PROXMOX_HOSTNAME` | `PKR_VAR_proxmox_hostname` | Proxmox API endpoint |
| `PROXMOX_PACKER_FRAMEWORK_TOKEN_ID` | `PKR_VAR_proxmox_api_token_id` | Proxmox API token ID |
| `PROXMOX_PACKER_FRAMEWORK_SECRET` | `PKR_VAR_proxmox_api_token_secret` | Proxmox API token secret |
| `PROXMOX_SKIP_TLS_VERIFY` | `PKR_VAR_proxmox_skip_tls_verify` | Top-level override. When set, it wins over `packer_image.insecure_skip_tls_verify`. This repo keeps `true` in the committed profile as a documented lab exception. |
| `PROXMOX_NODE` | `PKR_VAR_proxmox_node` | Top-level override. When set, it wins over `packer_image.node`. |
| `DEPLOY_USER_NAME` | `PKR_VAR_deploy_user_name` | Guest deploy account name |
| `.github/pins/secure-packer-bootstrapper.env` | tracked release pin file | Reviewed release repo, tag, asset URLs, and SHA256 consumed by CI |

The runtime bootstrap step generates these values immediately before `packer validate` and
`packer build`:

- `PKR_VAR_deploy_user_password`
- `PKR_VAR_deploy_user_password_hash`
- `PKR_VAR_deploy_user_key`
- `SPB_DEPLOY_USER_PASSWORD`
- `SPB_SSH_PRIVATE_KEY_FILE`
- `SPB_SSH_KEY_PASSPHRASE`

CI uses the generated SSH key for first-hop login, the generated password hash for Kickstart
`user --iscrypted`, and retains the plaintext password only for sudo / Ansible `become`.

### 4. Customize the Consumer Inputs

- `packer/systems.auto.pkrvars.hcl` carries real owner defaults for VM ID, node, storage, IP, and
  VLAN allocation. These are reserved owner defaults, not portable examples.
- `packer/ks.pkrtpl.hcl` owns the install-time guest baseline: partitioning, mount options,
  OpenSCAP STIG invocation, user creation, and post-install hardening commands.
- `packer/rocky-linux-9.yml` owns the consumer bootstrap playbook entrypoint. Reusable roles stay
  upstream in `ansible-framework`.

## Project Structure

```text
.
|-- .github/
|   |-- pins/                     # Reviewed secure-packer-bootstrapper release pin
|   |-- scripts/                  # CI helper scripts
|   `-- workflows/                # GitHub Actions workflows
|-- .config/                      # Markdown/YAML lint configuration
|-- .vscode/                      # Editor tasks/settings for the multi-repo workflow
|-- packer/
|   |-- framework-patches/        # Temporary framework compatibility overlay
|   |-- ks.pkrtpl.hcl            # Consumer-owned Kickstart template
|   |-- rocky-linux-9.yml        # Consumer-owned bootstrap playbook entrypoint
|   `-- systems.auto.pkrvars.hcl # Consumer-owned framework input profile
|-- tests/                       # Workflow-policy and pin-refresh unit tests
|-- .editorconfig
|-- .gitattributes
|-- .gitignore
|-- .pre-commit-config.yaml
|-- CHANGELOG.md
|-- CONTRIBUTING.md
|-- README.md
|-- SECURITY.md
`-- SUPPORT.md
```

## Validation Strategy

### Repo-local checks

- `pre-commit run --all-files`
- `yamllint` / `markdownlint-cli` / `packer fmt` against committed consumer files

### Composed framework validation

The real contract test for this repo happens after the consumer files are copied into
`../proxmox-packer-framework/packer` (local tasks) or
`${{ github.workspace }}/proxmox-packer-framework/packer` (CI). That composed path performs:

1. Apply the repo-owned compatibility overlay to the pinned framework checkout
2. Ansible syntax check against the pinned `../ansible-framework/ansible.cfg`
3. `packer init`
4. `packer validate`

### Branch-promotion gates

The PR workflow path owns the non-privileged gates:

1. Verify the tracked `secure-packer-bootstrapper` release pin is current
2. Run repo-native automation unit tests for the workflow contract and pin-refresh helper
3. Run `pre-commit run --all-files`
4. Verify the pinned Packer download against the tracked SHA256 before installing it
5. Check out the pinned framework repositories
6. Apply the repo-owned framework compatibility overlay
7. Run Ansible syntax validation plus composed `packer init` / `packer validate`

### Full integration build

Full build verification requires the self-hosted runner, Proxmox access, and the privileged CI
path in `.github/workflows/packer.yaml`.

### Native `packer test`

This repo does not currently ship local `.pkr.hcl` build definitions, so repo-root native
`packer test` is not the canonical test path here.

## VS Code Tasks

Press `Ctrl+Shift+B` to run the default
**Full Validation (Requires sibling frameworks)** task.

Framework-aware tasks are labeled explicitly and expect adjacent `proxmox-packer-framework` and
`ansible-framework` checkouts. Repo-local linting tasks remain available on their own.

## CI/CD Pipeline

| Workflow | Trigger | Purpose |
|---|---|---|
| **PR Verify** | Pull requests to `main` | Run branch-promotion gates: pin freshness, automation unit tests, repo-local checks, verified tool bootstrap, framework overlay validation, Ansible syntax validation, and composed `packer validate` |
| **Refresh secure-packer-bootstrapper Pin** | PR sync, weekly schedule, manual | Refresh the tracked release URLs and SHA256 in `.github/pins/secure-packer-bootstrapper.env` |
| **Packer Build** | Push to `main`, manual on `main` only | Run the trusted deployment path only: load the reviewed release pin, mint runtime credentials, perform final `packer validate`, and build |
| **Security Scan** | Push, PR, weekly schedule | Trivy filesystem/secret scan plus Gitleaks history scan |
| **CodeQL Analysis** | Push, PR, weekly schedule | Static analysis of GitHub Actions workflows |
| **Release Please** | Push to `main` | Semantic versioning and changelog generation for repo source/config only |

## GitHub Repository Controls

These protections live in GitHub settings rather than this checkout, but they are part of the
repository contract and should remain aligned with the workflow set:

- active rulesets on the default branch for signed commits, linear history, protected PR merges,
  and required status checks: `Branch Promotion Gates`, `Trivy (Filesystem & Secrets)`,
  `Gitleaks (Secret Scan)`, and `CodeQL (actions)`
- a real `packer-build` environment with deployment branch restrictions and reviewer protection
- repository-level SHA pinning required for GitHub Actions
- default `GITHUB_TOKEN` permissions set to read-only, with workflow review approval disabled

## VM Template Specifications

| Component | Configuration |
|---|---|
| **OS** | Rocky Linux 9.7 (x86_64) |
| **Boot** | UEFI (OVMF), Secure Boot, TPM 2.0 |
| **CPU** | 2 cores, host passthrough |
| **Memory** | 4096 MB |
| **Disk** | 100 GB LVM layout defined in `packer/ks.pkrtpl.hcl` |
| **Network** | virtio adapter, static owner-reserved IP/VLAN in the committed profile |
| **Provisioning** | Consumer-owned Kickstart template, OpenSCAP STIG install profile, bootstrap playbook entrypoint |
| **Cloud-Init** | Template-side Cloud-Init disk enabled; guest image installs the `cloud-init` package, but datasource behavior is not separately CI-validated |

### Disk Partitioning

| Partition | Size | Mount | Options |
|---|---|---|---|
| EFI | 1024 MB | `/boot/efi` | `nodev,nosuid` |
| Boot | 1024 MB | `/boot` | `nodev,nosuid` |
| Root | 10240 MB | `/` | - |
| Home | 4096 MB | `/home` | `nodev,nosuid,noexec` |
| Opt | 2048 MB | `/opt` | `nodev` |
| Tmp | 4096 MB | `/tmp` | `nodev,noexec,nosuid` |
| Var | 2048 MB | `/var` | `nodev,nosuid` |
| Var-Tmp | 1000 MB | `/var/tmp` | `nodev,noexec,nosuid` |
| Var-Log | 4096 MB | `/var/log` | `nodev,noexec,nosuid` |
| Var-Audit | 500 MB | `/var/log/audit` | `nodev,noexec,nosuid` |

## Security Controls Snapshot

### Direct controls implemented in this repo

| Control | Evidence | Notes |
|---|---|---|
| Locked root account | `packer/ks.pkrtpl.hcl` | `rootpw --lock` |
| SELinux enforcing | `packer/ks.pkrtpl.hcl` | Install-time baseline |
| firewalld enabled | `packer/ks.pkrtpl.hcl` | SSH explicitly allowed |
| Fixed LVM layout and mount options | `packer/ks.pkrtpl.hcl` | Partition table above reflects current Kickstart |
| Deploy user creation and SSH access | `packer/ks.pkrtpl.hcl` | Uses `user --iscrypted`, installs the runtime-generated public key, and disables SSH password authentication |
| SSH/SFTP normalization | `packer/ks.pkrtpl.hcl` and `packer/rocky-linux-9.yml` | Keeps the communicator working during bootstrap |
| Bootstrap playbook readiness checks | `packer/rocky-linux-9.yml` | Pre-task probes, connection reset, fact gathering |
| `cloud-init` package installation | `packer/ks.pkrtpl.hcl` | Guest package installed from Kickstart |

### Controls delegated at install time

| Control | Owner | Notes |
|---|---|---|
| DISA STIG profile application | OpenSCAP / SCAP Security Guide | Applied through `%addon com_redhat_oscap` |
| Additional STIG-managed guest settings | OpenSCAP / SCAP Security Guide | Version-sensitive and not fully enumerated here |

### Controls inherited from framework / platform wiring

| Control | Owner | Status |
|---|---|---|
| Template-side Cloud-Init disk attachment | `proxmox-packer-framework` + Proxmox VE | Enabled in the consumer profile |
| Ansible provisioner wiring and `roles_path` handoff | `proxmox-packer-framework` + `ansible-framework` | Active |

### Controls not yet evidenced here

| Control | Expected owner | Current state |
|---|---|---|
| Reusable Rocky Linux 9 hardening roles | `ansible-framework` | Not yet evidenced at the pinned upstream commit |
| Repo-owned runtime compliance validation | downstream operator or future CI | Not implemented in this repo |

## Release Semantics

Git tags and GitHub Releases in this repository version the consumer profile source and
configuration only. They do not, by themselves, attest a built Proxmox VM template artifact.
Auto-generated source archives are filtered by `.gitattributes`; they are not published VM
artifacts or a complete operator bundle.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution, validation, and update-policy guidance.

## Security

See [SECURITY.md](SECURITY.md) for vulnerability disclosure, runner trust-boundary notes, and
secret-detection coverage limits.

## Support

See [SUPPORT.md](SUPPORT.md) for the support boundary between this repo,
`proxmox-packer-framework`, `ansible-framework`, and downstream runtime operations.

## License

This project is licensed under the [MIT License](LICENSE).

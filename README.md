# Secure Rocky Linux 9 Template

[![Packer Build](https://github.com/NWarila/Secure-RockyLinux9-Template/actions/workflows/packer.yaml/badge.svg)](https://github.com/NWarila/Secure-RockyLinux9-Template/actions/workflows/packer.yaml)
[![Security Scan](https://github.com/NWarila/Secure-RockyLinux9-Template/actions/workflows/security.yaml/badge.svg)](https://github.com/NWarila/Secure-RockyLinux9-Template/actions/workflows/security.yaml)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A production-grade, security-hardened Rocky Linux 9 virtual machine template built with
[HashiCorp Packer](https://www.packer.io/) for
[Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment/overview). This template
integrates with the
[Proxmox-Packer-Framework](https://github.com/NWarila/Proxmox-Packer-Framework) to produce
golden images ready for enterprise deployment.

## Features

| Category | Tools |
|---|---|
| **OS Hardening** | CIS-aligned partitioning, mount options (`nodev`, `noexec`, `nosuid`) |
| **Provisioning** | Consumer-owned Kickstart template, Ansible post-configuration |
| **Infrastructure** | Proxmox VE integration, UEFI/OVMF boot, TPM 2.0, Cloud-Init |
| **Formatting** | `packer fmt`, markdownlint, yamllint, `.editorconfig` |
| **Security** | Trivy (HIGH/CRITICAL), Gitleaks, CodeQL, `detect-private-key` |
| **Commit Quality** | Conventional Commits enforced via pre-commit hook |
| **CI/CD** | GitHub Actions (build, security scan, release automation) |
| **Dependency Mgmt** | Dependabot (GitHub Actions ecosystem) |

## Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| [Packer](https://www.packer.io/) | >= 1.15 | VM template builder |
| [Ansible](https://docs.ansible.com/) | latest | Post-build provisioning |
| [pre-commit](https://pre-commit.com/) | >= 4.0.0 | Git hook framework |
| [Gitleaks](https://github.com/gitleaks/gitleaks) | >= 8.24.0 | Secret detection |
| [yamllint](https://github.com/adrienverge/yamllint) | latest | YAML linting |
| [markdownlint-cli](https://github.com/igorshubovych/markdownlint-cli) | latest | Markdown linting |

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/NWarila/Secure-RockyLinux9-Template.git
cd Secure-RockyLinux9-Template
```

### 2. Install Pre-Commit Hooks

```bash
pip install pre-commit
pre-commit install --hook-type pre-commit --hook-type pre-push --hook-type commit-msg
```

### 3. Configure Environment

Set the required secrets in your GitHub repository settings (or export locally for testing):

| Variable | Description |
|---|---|
| `PROXMOX_HOSTNAME` | Proxmox API endpoint (secret) |
| `PROXMOX_PACKER_FRAMEWORK_TOKEN_ID` | API token ID (secret) |
| `PROXMOX_PACKER_FRAMEWORK_SECRET` | API token secret (secret) |
| `PROXMOX_NODE` | Target Proxmox node (secret) |
| `PROXMOX_SKIP_TLS_VERIFY` | Skip TLS verification (variable, default `false`) |
| `DEPLOY_USER_NAME` | Deploy user account name (secret) |
| `DEPLOY_USER_PASSWORD` | Deploy user password (secret) |
| `DEPLOY_USER_PUBLIC_KEY` | Deploy user SSH public key (secret) |

### 4. Customize the Template

Edit `packer/systems.auto.pkrvars.hcl` to match your environment (VM ID, network, storage pools,
etc.). Customize `packer/ks.pkrtpl.hcl` if you need to modify the fixed partitioning scheme or the
Kickstart installation template. Customize `packer/rocky-linux-9.yml` if you need to adjust the
consumer-owned Ansible entrypoint.

## Project Structure

```text
.
├── packer/                     # Consumer-owned Packer inputs
│   ├── ks.pkrtpl.hcl           #   Kickstart template (framework contract)
│   ├── rocky-linux-9.yml       #   Post-build hardening playbook
│   └── systems.auto.pkrvars.hcl #  Packer variables (VM configuration)
├── .config/                    # Linter and tool configurations
│   ├── .markdownlint.json      #   Markdown linting rules
│   └── .yamllint.yaml          #   YAML linting rules
├── .github/
│   ├── CODEOWNERS              # Code review ownership
│   ├── FUNDING.yml             # Sponsorship configuration
│   ├── dependabot.yml          # Automated dependency updates
│   ├── pull_request_template.md
│   ├── ISSUE_TEMPLATE/         # Structured issue forms
│   └── workflows/
│       ├── packer.yaml         #   Build & validate pipeline
│       ├── security.yaml       #   Trivy + Gitleaks scanning
│       ├── codeql.yaml         #   CodeQL SAST analysis
│       └── release-please.yaml #   Automated versioning
├── .vscode/                    # Editor workspace configuration
│   ├── extensions.json         #   Recommended extensions
│   ├── settings.json           #   Editor settings
│   └── tasks.json              #   Build & validation tasks
├── .editorconfig               # Cross-editor formatting
├── .gitattributes              # Line endings, linguist, export-ignore
├── .gitignore                  # Allowlist-style ignore rules
├── .pre-commit-config.yaml     # Git hook definitions
├── .release-please-manifest.json
├── release-please-config.json
├── CHANGELOG.md                # Auto-generated changelog
├── CODE_OF_CONDUCT.md          # Contributor Covenant
├── CONTRIBUTING.md             # Contribution guidelines
├── LICENSE                     # MIT License
├── README.md
├── SECURITY.md                 # Security policy & disclosure
└── SUPPORT.md                  # Support scope & guidelines
```

## Developer Workflow

### Pre-Commit Hooks

Every commit and push runs automated checks:

- **File quality** - trailing whitespace, line endings, large files, merge conflicts
- **Secret detection** - Gitleaks scans for hardcoded secrets
- **Packer formatting** - `packer fmt -check` enforces canonical HCL style
- **YAML linting** - validates all YAML files against strict rules
- **Markdown linting** - enforces consistent documentation style
- **Conventional Commits** - commit messages must follow the specification

### VS Code Tasks

Press `Ctrl+Shift+B` to run the **Full Validation** composite task, or run individual tasks:

- **Packer: Format** / **Format Check** / **Init** / **Validate**
- **YAML Lint** / **Markdown Lint**
- **Trivy: Security Scan**
- **Pre-Commit: Run All**

## CI/CD Pipeline

| Workflow | Trigger | Purpose |
|---|---|---|
| **Packer Build** | Push to `main`, manual | Format, validate, and build the VM template |
| **Security Scan** | Push, PR, weekly schedule | Trivy filesystem/secret scan + Gitleaks |
| **CodeQL Analysis** | Push, PR, weekly schedule | Static analysis of GitHub Actions workflows |
| **Release Please** | Push to `main` | Automated semantic versioning and changelog |

## VM Template Specifications

| Component | Configuration |
|---|---|
| **OS** | Rocky Linux 9.6 (x86_64) |
| **Boot** | UEFI (OVMF), TPM 2.0 |
| **CPU** | 2 cores, host passthrough |
| **Memory** | 4096 MB |
| **Disk** | 100 GB (LVM, security-hardened partitioning) |
| **Network** | virtio adapter, VLAN-tagged |
| **Provisioning** | Kickstart (consumer-owned template) + Cloud-Init + Ansible |

### Disk Partitioning (CIS-Aligned)

| Partition | Size | Mount | Options |
|---|---|---|---|
| EFI | 1024 MB | `/boot/efi` | - |
| Boot | 1024 MB | `/boot` | - |
| Root | 10240 MB | `/` | - |
| Home | 4096 MB | `/home` | `nodev,nosuid` |
| Opt | 2048 MB | `/opt` | `nodev` |
| Tmp | 4096 MB | `/tmp` | `nodev,noexec,nosuid` |
| Var | 2048 MB | `/var` | `nodev` |
| Var-Tmp | 1000 MB | `/var/tmp` | `nodev,noexec,nosuid` |
| Var-Log | 4096 MB | `/var/log` | `nodev,noexec,nosuid` |
| Var-Audit | 500 MB | `/var/log/audit` | `nodev,noexec,nosuid` |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute.

## Security

See [SECURITY.md](SECURITY.md) for the vulnerability disclosure policy.

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2025 Trinity-Technical-Services-LLC

# Security Policy

## Supported Versions

Only the latest commit on `main` is actively maintained. Security fixes are applied to `main` and
released from there.

## Reporting a Vulnerability

This project follows coordinated disclosure. **Do not open a public issue for security
vulnerabilities.**

**Email:** reports@TrinityTechnicalServices.com

Please include:

- a description of the issue
- the affected component or file
- steps to reproduce
- expected versus actual behavior
- any suggested remediation

### Response Timeline

| Stage | Timeline |
|---|---|
| Acknowledgement | Within 48 hours |
| Assessment | Within 5 business days |
| Resolution | Before public disclosure |

## Security Controls

### Local (`pre-commit`)

- **Gitleaks** scans staged changes for secrets.
- **detect-private-key** blocks accidental private-key commits.
- **check-added-large-files** blocks oversized files.
- **packer fmt**, **yamllint**, and **markdownlint-cli** keep committed consumer inputs reviewable.

### CI (GitHub Actions)

- **Trivy** scans this repository checkout for filesystem issues, misconfigurations, and secrets.
- **Gitleaks** scans repository history.
- **CodeQL** analyzes GitHub Actions workflow content.
- **PR Verify** shifts formatting, linting, and composed validation into branch-promotion gates
  before merge.
- **Refresh secure-packer-bootstrapper Pin** keeps the tracked bootstrapper release URLs and
  SHA256 in version control instead of hidden repo settings.
- **secure-packer-bootstrapper** is downloaded from the tracked reviewed release pin and verified
  against the committed SHA256 before the privileged build uses it.
- **SHA-pinned actions** reduce mutable supply-chain risk.

### Supply Chain

- **Dependabot** tracks GitHub Actions and `pre-commit` updates.
- **persist-credentials: false** is used on checkout steps.
- External framework repositories are checked out by immutable commit SHA in `packer.yaml`.

## Self-Hosted Runner Trust Boundary

The privileged Packer build runs on a **persistent** self-hosted runner. This repository is
**public**, so that trust boundary matters:

- `.github/workflows/packer.yaml` intentionally excludes `pull_request`.
- The privileged trigger paths are `push` to `main` and `workflow_dispatch`.
- The workflow rejects non-`main` refs even when a user manually dispatches it.
- Formatting, linting, and composed validation are handled in the PR workflow path, not on the
  privileged deployment runner.
- The workflow checks out this repo plus `proxmox-packer-framework` and `ansible-framework` into
  the same runner workspace before invoking Packer and Ansible.
- The build job receives Proxmox API credentials, repo-owned deploy-user identity, reviewed
  bootstrapper release pins from the committed env file, and node-selection inputs through
  environment variables.

Current operator expectations for the persistent runner:

- dedicated use for this privileged build path
- restricted repository / workflow access through runner-group policy outside git
- full workspace, artifact, and tool-cache cleanup between jobs performed by the runner operator;
  this repo now deletes its generated bootstrap directory, but it does not scrub the entire runner
  workspace
- monitoring and auditability appropriate for a runner that can retain state between jobs

Current network expectations for the runner:

- reachability to GitHub for repository checkouts
- reachability to the Proxmox API and build network
- any additional egress required by the consumer Kickstart / Ansible bootstrap path

Build-time secret handoff details:

- the rendered Kickstart contains the deploy-user password hash and SSH public key, not the
  plaintext password
- the privileged workflow downloads the reviewed `secure-packer-bootstrapper` release bundle,
  verifies its checksum, and generates the plaintext password, password hash, SSH keypair, and
  key passphrase at runtime
- the upstream Packer communicator uses SSH agent authentication with the generated key
- the upstream Ansible provisioner still passes the plaintext password through `--extra-vars` for
  sudo / `become`
- persistent-runner hygiene therefore matters as much as scanner coverage

## Secret-Detection Coverage Boundary

What the configured scanners cover:

- committed source in this repository
- repository history (`gitleaks`)
- the CI checkout of this repository (`trivy`, `gitleaks`)

What they do **not** cover in this repository's current architecture:

- the generated bootstrap directory under `$RUNNER_TEMP`
- rendered Kickstart output with injected password hash / public key material
- external checkouts of `proxmox-packer-framework` and `ansible-framework`
- process arguments, process memory, or transient shell history on the self-hosted runner
- build logs and artifacts after they are produced

Build-time secrets therefore rely on a combination of:

- reviewed bootstrapper release pins plus checksum verification
- upstream `sensitive` variable handling in the framework contract
- restricted runner access
- runner cleanup and media lifecycle hygiene
- careful log review

## TLS Verification Exception

The committed consumer profile currently keeps `packer_image.insecure_skip_tls_verify = true` as a
documented **lab exception** for owner-operated builds while certificate work remains unresolved.
This is not recommended as a general default. Where trusted certificates are available, set the
top-level `PKR_VAR_proxmox_skip_tls_verify=false` override and remove the exception when the lab
can rely on normal certificate validation.

## Scope

### In Scope

- secrets or credentials exposed in repository content
- CI/CD workflow vulnerabilities
- insecure consumer-profile, Kickstart, or bootstrap-playbook defaults
- supply-chain and dependency-update governance in this repository

### Out of Scope

- downstream runtime operations for VMs built from this profile
- Proxmox VE platform vulnerabilities
- vulnerabilities in third-party tools or upstream frameworks themselves
- physical access or broader network-security issues outside the runner / build path

# Contributing

Thank you for helping improve this repository. This project is a consumer-profile repo, so useful
changes are often about making the repo boundary, build contract, and hardening evidence clearer
in addition to changing the profile files themselves.

## Ways to Contribute

- report bugs via the issue templates
- improve the consumer profile under `packer/`
- improve documentation, release semantics, or contributor guidance
- refine workflows, validation gates, or security tooling in this repository

## Where to Contribute

| Change type | Repository |
|---|---|
| Consumer profile values, Kickstart layout, bootstrap playbook entrypoint, repo docs | This repository |
| Packer build logic, framework variable contract, normalization logic | `proxmox-packer-framework` |
| Reusable Ansible roles, shared Ansible config behavior, Rocky Linux role implementation | `ansible-framework` |

## Getting Started

1. Fork the repository and branch from `main`.
2. Make your changes.
3. Run the repo-local checks that match your change.
4. If you touched the composed build path, run the framework-aware validation path too.
5. Open a pull request against `main`.

Pull requests to `main` automatically run the `PR Verify` workflow, and same-repo PR branches can
also receive an automatic refresh of `.github/pins/secure-packer-bootstrapper.env` when the
bootstrapper release pin is stale.

## Validation Strategy

### Repo-local validation

For most changes in this repository, local validation means:

- `python -m unittest discover -s tests -p "test_*.py" -v`
- `pre-commit run --all-files`
- any repo-local lint or formatting tasks related to the files you changed

### Framework-aware validation

This repository's canonical Packer validation path is composed with sibling checkouts:

- `../proxmox-packer-framework`
- `../ansible-framework`

That path is what the default VS Code validation task and CI workflow use. It currently includes:

- repo-local `packer fmt -check -diff packer`
- sync the consumer files into `../proxmox-packer-framework/packer`
- Ansible syntax check against `../ansible-framework/ansible.cfg`
- `packer init`
- `packer validate`

### Full integration testing

Full image-build verification requires the self-hosted runner, Proxmox access, and the privileged
CI workflow. This repo does not define a standalone repo-root `packer test` path today because the
tracked artifact here is the consumer profile, not local `.pkr.hcl` builders.

## Tooling Notes

- `.editorconfig` covers indentation, line endings, and trailing whitespace.
- Line-length guidance is intentionally split:
  - general editing guidance comes from VS Code rulers at 96 / 98 columns
  - Markdown and YAML enforcement comes from their linters at 120 columns

## Dependency and Compatibility Updates

When changing framework SHAs in `.github/workflows/packer.yaml` or hook pins in
`.pre-commit-config.yaml`:

1. rerun `pre-commit run --all-files`
2. rerun the composed framework validation path
3. update the README compatibility / validated-with notes if the effective contract changed

Dependabot is the preferred path for GitHub Actions and `pre-commit` pin refresh PRs. The
bootstrapper release URL and SHA256 pin are refreshed through
`.github/workflows/refresh-bootstrapper-pin.yaml` into
`.github/pins/secure-packer-bootstrapper.env`.

`actionlint` is a required PR gate in CI even if it is not installed locally. If you change
workflow files, run the repo-native tests and expect CI to enforce workflow syntax and policy.

When the upstream `secure-packer-bootstrapper` release changes, treat
`.github/pins/secure-packer-bootstrapper.env` as the source of truth for the reviewed release URL
set and SHA256 consumed by the privileged build workflow.

## Commit Messages

This project enforces [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>: <description>

[optional body]

[optional footer(s)]
```

Allowed types: `feat`, `fix`, `ci`, `docs`, `refactor`, `test`, `chore`, `security`

## Pull Request Guidelines

- keep each PR focused on one logical change
- update docs when behavior, scope, or version assumptions change
- say which validation path you used: repo-local, framework-aware, or CI-only
- be explicit when a change depends on sibling framework repos or self-hosted runner behavior

## Code of Conduct

All contributors are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

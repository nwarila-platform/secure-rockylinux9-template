# Manual Packer Build

Use this runbook when the privileged GitHub Actions path is unavailable or when
the maintainer needs to reproduce the build from a trusted host with Proxmox
reach. The normal hosted PR path still runs validation only; the live build
requires the `packer-build` environment, Proxmox access, and runtime secrets.

## Preconditions

- Run from a trusted Linux host that can reach the Proxmox API and the target
  node.
- Install the exact tool versions used by CI:
  - Packer `1.15.0`
  - Terraform `1.15.1`
  - Ansible Core `>= 2.17, < 2.19` (e.g. `2.18.x`), per the pinned
    `ansible-framework` `requirements-dev.txt` constraint
- Clone these repositories as siblings:
  - `secure-rockylinux9-template`
  - `proxmox-packer-framework`
  - `ansible-framework`
- Export the Proxmox, HCP Terraform, and deploy-user inputs described in the
  repository README.
- Confirm `.github/pins/secure-packer-bootstrapper.env` points to a reviewed
  `secure-packer-bootstrapper` release and SHA256.

## Prepare the ISO Input

From `secure-rockylinux9-template/terraform`, initialize and apply the ISO
manager root so the framework receives the generated Packer var file:

```bash
terraform init
terraform apply -auto-approve
test -f iso-manager.auto.pkrvars.hcl
```

This uses the reviewed Rocky ISO URL, filename, and SHA256 in
`terraform/terraform.tfvars`.

## Sync Consumer Files

Copy this repo's consumer-owned inputs into the framework checkout:

```bash
repo_root="$(pwd)"
framework_dir="${repo_root}/../proxmox-packer-framework/packer"

cp -f packer/systems.auto.pkrvars.hcl "${framework_dir}/"
cp -f packer/ks.pkrtpl.hcl "${framework_dir}/"
cp -f packer/rocky-linux-9.yml "${framework_dir}/"
cp -f terraform/iso-manager.auto.pkrvars.hcl "${framework_dir}/"
```

## Load Runtime Bootstrap Credentials

Load the reviewed bootstrapper pin and run the release bundle in the same shell
that will execute Packer:

```bash
set -a
. .github/pins/secure-packer-bootstrapper.env
set +a

bootstrap_dir="$(mktemp -d)"
curl --fail --location "${SECURE_PACKER_BOOTSTRAPPER_RELEASE_URL}" \
  -o "${bootstrap_dir}/secure-packer-bootstrapper.sh"
printf '%s  %s\n' \
  "${SECURE_PACKER_BOOTSTRAPPER_RELEASE_SHA256}" \
  "${bootstrap_dir}/secure-packer-bootstrapper.sh" | sha256sum -c -
chmod 700 "${bootstrap_dir}/secure-packer-bootstrapper.sh"

eval "$("${bootstrap_dir}/secure-packer-bootstrapper.sh" --output-dir "${bootstrap_dir}/artifacts")"
```

Keep this shell private. It now contains deploy-user credentials and SSH key
paths used by Packer and Ansible.

## Validate and Build

From the framework Packer directory:

```bash
cd ../proxmox-packer-framework/packer
packer init .
packer validate .
packer build -force -timestamp-ui -color=false -on-error=cleanup .
```

If the build fails before guest provisioning, inspect Proxmox credentials,
token permissions, storage names, node names, and the generated
`iso-manager.auto.pkrvars.hcl`. If it fails during Ansible provisioning,
inspect SSH/SFTP normalization and the runtime-generated deploy-user
credentials.

## Cleanup

After the run:

```bash
ssh-add -D >/dev/null 2>&1 || true
rm -rf "${bootstrap_dir}"
unset PKR_VAR_deploy_user_password
unset PKR_VAR_deploy_user_password_hash
unset PKR_VAR_deploy_user_key
unset SPB_DEPLOY_USER_PASSWORD
unset SPB_SSH_PRIVATE_KEY_FILE
unset SPB_SSH_KEY_PASSPHRASE
```

Do not commit generated Packer logs, bootstrapper artifacts, SSH keys, or
Terraform state.

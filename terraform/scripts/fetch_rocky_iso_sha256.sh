#!/usr/bin/env bash
set -euo pipefail

ROCKY_ISO_BASE_URL="${ROCKY_ISO_BASE_URL:-https://download.rockylinux.org/pub/rocky/9/isos/x86_64}"
ROCKY_ISO_FILENAME="${ROCKY_ISO_FILENAME:-Rocky-9.8-x86_64-dvd.iso}"
ROCKY_GPG_KEY_URL="${ROCKY_GPG_KEY_URL:-https://download.rockylinux.org/pub/rocky/RPM-GPG-KEY-Rocky-9}"
ROCKY_GPG_FINGERPRINT="${ROCKY_GPG_FINGERPRINT:-21CB256AE16FC54C6E652949702D426D350D275D}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

require_command awk
require_command chmod
require_command curl
require_command gpg
require_command mkdir
require_command mktemp
require_command rm

workdir="$(mktemp -d)"
cleanup() {
  rm -rf "${workdir}"
}
trap cleanup EXIT

checksum_file="${workdir}/CHECKSUM"
signature_file="${workdir}/CHECKSUM.asc"
key_file="${workdir}/RPM-GPG-KEY-Rocky-9"
gnupghome="${workdir}/gnupg"

mkdir -p "${gnupghome}"
chmod 700 "${gnupghome}"

base_url="${ROCKY_ISO_BASE_URL%/}"
curl --fail --silent --show-error --location "${base_url}/CHECKSUM" -o "${checksum_file}"
curl --fail --silent --show-error --location "${base_url}/CHECKSUM.asc" -o "${signature_file}"
curl --fail --silent --show-error --location "${ROCKY_GPG_KEY_URL}" -o "${key_file}"

gpg --homedir "${gnupghome}" --import "${key_file}" >/dev/null

actual_fingerprint="$(
  gpg --homedir "${gnupghome}" --with-colons --fingerprint "${ROCKY_GPG_FINGERPRINT}" |
    awk -F: '$1 == "fpr" { print $10; exit }'
)"

if [[ "${actual_fingerprint}" != "${ROCKY_GPG_FINGERPRINT}" ]]; then
  echo "Rocky GPG key fingerprint mismatch." >&2
  echo "Expected: ${ROCKY_GPG_FINGERPRINT}" >&2
  echo "Actual:   ${actual_fingerprint:-<missing>}" >&2
  exit 1
fi

gpg --homedir "${gnupghome}" --verify "${signature_file}" "${checksum_file}" >&2

awk -v iso="${ROCKY_ISO_FILENAME}" '
  $1 == "SHA256" && $2 == "(" iso ")" && $3 == "=" && length($4) == 64 && $4 ~ /^[0-9a-f]+$/ {
    print $4
    found = 1
  }
  END {
    if (!found) {
      exit 1
    }
  }
' "${checksum_file}" || {
  echo "No SHA256 entry found for ${ROCKY_ISO_FILENAME} in signed CHECKSUM." >&2
  exit 1
}

#!/usr/bin/env python3
"""Refresh or verify the tracked secure-packer-bootstrapper release pin file."""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import sys
import urllib.error
import urllib.request
from urllib.parse import urlparse


REQUIRED_ASSETS = {
    "bundle": "secure-packer-bootstrapper.sh",
    "checksum": "secure-packer-bootstrapper.sh.sha256",
    "metadata": "secure-packer-bootstrapper.release.json",
}

USER_AGENT = "secure-rockylinux9-template-pin-refresh"
TAG_PATTERN = re.compile(r"^v[0-9][0-9A-Za-z._-]*$")
TIMEOUT_SECONDS = 20


def build_request(url: str, token: str | None) -> urllib.request.Request:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": USER_AGENT,
        "X-GitHub-Api-Version": "2022-11-28",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return urllib.request.Request(url, headers=headers)


def fetch_json(url: str, token: str | None) -> dict | None:
    try:
        with urllib.request.urlopen(build_request(url, token), timeout=TIMEOUT_SECONDS) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            return None
        raise


def fetch_text(url: str, token: str | None) -> str:
    with urllib.request.urlopen(build_request(url, token), timeout=TIMEOUT_SECONDS) as response:
        return response.read().decode("utf-8")


def parse_checksum(raw_text: str) -> str:
    first_field = raw_text.strip().split()[0] if raw_text.strip() else ""
    if not re.fullmatch(r"[0-9a-fA-F]{64}", first_field):
        raise ValueError("Checksum asset did not contain a valid SHA256 digest.")
    return first_field.lower()


def validate_tag(tag_name: str) -> str:
    normalized = tag_name.strip()
    if not TAG_PATTERN.fullmatch(normalized):
        raise ValueError("Latest release tag_name did not match the expected reviewed tag format.")
    return normalized


def validate_release_asset_url(url: str, repo: str, tag: str, asset_name: str) -> str:
    parsed = urlparse(url)
    expected_path = f"/{repo}/releases/download/{tag}/{asset_name}"
    if parsed.scheme != "https":
        raise ValueError(f"Release asset URL must use HTTPS: {url}")
    if parsed.netloc != "github.com":
        raise ValueError(f"Release asset URL must resolve to github.com: {url}")
    if parsed.path != expected_path:
        raise ValueError(f"Release asset URL did not match the expected GitHub release path for {asset_name}.")
    return url


def render_pin_file(repo: str, tag: str, bundle_url: str, sha256: str, sha256_url: str, metadata_url: str) -> str:
    return "\n".join(
        [
            "# Reviewed secure-packer-bootstrapper release pin.",
            "# This file is intentionally committed so PRs can update and review the",
            "# bootstrapper release URL set and checksum in version control.",
            "# Managed by .github/scripts/refresh_secure_packer_bootstrapper_pin.py.",
            f"SECURE_PACKER_BOOTSTRAPPER_RELEASE_REPO={repo}",
            f"SECURE_PACKER_BOOTSTRAPPER_RELEASE_TAG={tag}",
            f"SECURE_PACKER_BOOTSTRAPPER_RELEASE_URL={bundle_url}",
            f"SECURE_PACKER_BOOTSTRAPPER_RELEASE_SHA256={sha256}",
            f"SECURE_PACKER_BOOTSTRAPPER_RELEASE_SHA256_URL={sha256_url}",
            f"SECURE_PACKER_BOOTSTRAPPER_RELEASE_METADATA_URL={metadata_url}",
            "",
        ]
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", required=True, help="owner/name GitHub repository for secure-packer-bootstrapper")
    parser.add_argument("--output", required=True, help="Path to the tracked env-style pin file")
    parser.add_argument("--check", action="store_true", help="Fail if the output file is stale")
    parser.add_argument("--write", action="store_true", help="Write the updated output file when needed")
    parser.add_argument(
        "--allow-missing-release",
        action="store_true",
        help="Treat an unpublished release set as a no-op instead of a failure",
    )
    args = parser.parse_args()

    if args.check == args.write:
        parser.error("Choose exactly one of --check or --write.")

    output_path = pathlib.Path(args.output)
    token = os.environ.get("GITHUB_TOKEN")
    release_api_url = f"https://api.github.com/repos/{args.repo}/releases/latest"

    try:
        release = fetch_json(release_api_url, token)
        if release is None:
            if args.allow_missing_release:
                print(f"No published release found for {args.repo}; leaving {output_path} unchanged.")
                return 0
            print(f"No published release found for {args.repo}.", file=sys.stderr)
            return 1

        tag_name = validate_tag(release.get("tag_name", ""))

        assets_by_name = {asset.get("name"): asset for asset in release.get("assets", [])}
        missing_assets = [name for name in REQUIRED_ASSETS.values() if name not in assets_by_name]
        if missing_assets:
            print(f"Latest release is missing required assets: {', '.join(missing_assets)}", file=sys.stderr)
            return 1

        bundle_url = validate_release_asset_url(
            assets_by_name[REQUIRED_ASSETS["bundle"]]["browser_download_url"],
            args.repo,
            tag_name,
            REQUIRED_ASSETS["bundle"],
        )
        checksum_url = validate_release_asset_url(
            assets_by_name[REQUIRED_ASSETS["checksum"]]["browser_download_url"],
            args.repo,
            tag_name,
            REQUIRED_ASSETS["checksum"],
        )
        metadata_url = validate_release_asset_url(
            assets_by_name[REQUIRED_ASSETS["metadata"]]["browser_download_url"],
            args.repo,
            tag_name,
            REQUIRED_ASSETS["metadata"],
        )
        checksum_text = fetch_text(checksum_url, token)
        sha256 = parse_checksum(checksum_text)

        rendered = render_pin_file(
            repo=args.repo,
            tag=tag_name,
            bundle_url=bundle_url,
            sha256=sha256,
            sha256_url=checksum_url,
            metadata_url=metadata_url,
        )

        current = output_path.read_text(encoding="utf-8") if output_path.exists() else ""
        if current == rendered:
            print(f"{output_path} is already pinned to {tag_name}.")
            return 0

        if args.check:
            print(f"{output_path} is stale and should be refreshed to {tag_name}.", file=sys.stderr)
            return 1

        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(rendered, encoding="utf-8")
        print(f"Updated {output_path} to {tag_name}.")
        return 0
    except (urllib.error.URLError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

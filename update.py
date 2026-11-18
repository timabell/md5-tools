#!/usr/bin/env python3
"""
Bump flake.nix to the latest md5-tools release.

Reads SHA256SUMS.txt from the latest GitHub release, rewrites version + per-system
sha256 fields in flake.nix in place. Idempotent — exits cleanly if already current.

Run locally or from a CI cron. No third-party dependencies.
"""
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

REPO = "timabell/md5-tools"
FLAKE = Path(__file__).parent / "flake.nix"

ASSET_FOR_SYSTEM = {
    "x86_64-linux": "md5-tools-linux-x86_64.tar.gz",
}


def fetch(url: str) -> str:
    req = urllib.request.Request(url)
    token = os.environ.get("GITHUB_TOKEN")
    # API only: release downloads redirect to a CDN that rejects the header
    if token and url.startswith("https://api.github.com/"):
        req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode()


def main() -> int:
    if not os.environ.get("GITHUB_TOKEN"):
        print("warning: GITHUB_TOKEN not set, GitHub API calls are liable to be rate limited", file=sys.stderr)

    flake = FLAKE.read_text()

    latest = json.loads(fetch(f"https://api.github.com/repos/{REPO}/releases/latest"))
    tag = latest["tag_name"]
    version = tag.lstrip("v")

    current_match = re.search(r'version = "([^"]+)"', flake)
    if current_match is None:
        print("could not find version field in flake.nix", file=sys.stderr)
        return 1
    current = current_match.group(1)

    if current == version:
        print(f"already at {version}, nothing to do")
        return 0

    print(f"updating {current} -> {version}")

    sums_text = fetch(f"https://github.com/{REPO}/releases/download/{tag}/SHA256SUMS.txt")
    sums = {}
    for line in sums_text.strip().splitlines():
        h, name = line.split(maxsplit=1)
        sums[name.strip()] = h

    missing = [a for a in ASSET_FOR_SYSTEM.values() if a not in sums]
    if missing:
        print(f"missing assets in SHA256SUMS.txt: {missing}", file=sys.stderr)
        return 1

    flake = re.sub(r'version = "[^"]+"', f'version = "{version}"', flake, count=1)

    for system, asset in ASSET_FOR_SYSTEM.items():
        h = sums[asset]
        # Match `<system> = { ... sha256 = "<old>"; ... };` and swap the hash inside.
        pattern = re.compile(
            rf'({re.escape(system)}\s*=\s*\{{[^}}]*?sha256\s*=\s*")[^"]+(")',
            re.DOTALL,
        )
        new_flake, n = pattern.subn(rf'\g<1>{h}\g<2>', flake, count=1)
        if n != 1:
            print(f"failed to update sha256 for {system}", file=sys.stderr)
            return 1
        flake = new_flake

    FLAKE.write_text(flake)
    print(f"wrote flake.nix at {version}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

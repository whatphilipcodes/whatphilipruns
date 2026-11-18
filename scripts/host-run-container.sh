#!/usr/bin/env bash
# Host: run scripts/container-provision.sh inside the image.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Persist /nix (fetched flake inputs, eval caches, tools) between runs.
# Keyed by image id so a rebuilt image gets a fresh volume instead of a stale one.
image_id=$(podman image inspect --format '{{.Id}}' "$IMAGE_TAG")
nix_volume="hcloud-nixos-store-${image_id:0:12}"

tty_flags=(-i)
if [ -t 0 ] && [ -t 1 ]; then tty_flags=(-it); fi

podman run --rm --init --platform linux/arm64 "${tty_flags[@]}" \
  -v "$ROOT:/work" -w /work \
  -v "$SSH_DIR:/host-ssh:ro" \
  -v "$nix_volume:/nix" \
  "$IMAGE_TAG" bash /work/scripts/container-provision.sh
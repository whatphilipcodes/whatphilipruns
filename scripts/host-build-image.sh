#!/usr/bin/env bash
# Host: build the linux/arm64 tooling image from ./Containerfile.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Empty build context: the repo (with .git and .env) is not sent to the build.
ctx=$(mktemp -d)
trap 'rm -rf "$ctx"' EXIT

echo "Building arm64 tooling image (first run takes a few minutes) ..."
# shellcheck disable=SC2086
podman build --platform linux/arm64 ${REBUILD_IMAGE:+--no-cache} \
  -f "$CONTAINERFILE" \
  --build-arg "NIX_IMAGE=$NIX_IMAGE" --build-arg "NIXPKGS_REF=$NIXPKGS_REF" \
  -t "$IMAGE_TAG" "$ctx"
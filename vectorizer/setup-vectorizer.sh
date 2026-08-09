#!/bin/bash
set -e

if [ "$(id -un)" != "podman" ]; then
    echo "Error: This script must be run as the podman user." >&2
    exit 1
fi

export XDG_RUNTIME_DIR="/run/user/$(id -u)"

if ! podman image exists vectorizer:latest; then
    echo "Error: Image vectorizer:latest does not exist. Build the image first." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUADLET_DIR="$HOME/.config/containers/systemd"

mkdir -p "$HOME/vectorizer"
mkdir -p "$QUADLET_DIR"

systemctl --user stop vectorizer.service 2>/dev/null || true

rm -f "$QUADLET_DIR"/vectorizer.*

cp -rf "$SCRIPT_DIR/systemd/"* "$QUADLET_DIR/"

systemctl --user daemon-reload
systemctl --user start vectorizer.service
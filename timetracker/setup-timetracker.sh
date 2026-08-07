#!/bin/bash
set -e

if [ "$(id -un)" != "podman" ]; then
    echo "Error: This script must be run as the podman user." >&2
    exit 1
fi

if ! podman image exists timetracker:latest; then
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUADLET_DIR="$HOME/.config/containers/systemd"

mkdir -p "$HOME/timetracker"
mkdir -p "$QUADLET_DIR"

systemctl --user stop timetracker.service || true

rm -f "$QUADLET_DIR"/timetracker.*

cp -rf "$SCRIPT_DIR/systemd/"* "$QUADLET_DIR/"

systemctl --user daemon-reload
systemctl --user start timetracker.service
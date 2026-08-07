#!/bin/bash
set -e

if [ "$(id -un)" != "podman" ]; then
    echo "Error: This script must be run as the podman user." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUADLET_DIR="$HOME/.config/containers/systemd"

mkdir -p "$HOME/caddy"
mkdir -p "$QUADLET_DIR"

cp -f "$SCRIPT_DIR/Caddyfile" "$HOME/caddy/Caddyfile"

systemctl --user stop caddy.service || true

rm -f "$QUADLET_DIR"/caddy.*
rm -f "$QUADLET_DIR"/caddy_*
rm -f "$QUADLET_DIR"/web.*

cp -rf "$SCRIPT_DIR/systemd/"* "$QUADLET_DIR/"

systemctl --user daemon-reload
systemctl --user start caddy.service
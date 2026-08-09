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

if ! podman secret exists timetracker_api_token; then
    token=$(pwgen -s 32 1 | tr -d '\n')
    printf "New API Access Token (Save this now, it will not be displayed again): %s\n" "$token" >&2
    printf "%s" "$token" | podman secret create timetracker_api_token - > /dev/null
    unset token
fi

systemctl --user stop timetracker.service || true

rm -f "$QUADLET_DIR"/timetracker.*

cp -rf "$SCRIPT_DIR/systemd/"* "$QUADLET_DIR/"

systemctl --user daemon-reload
systemctl --user start timetracker.service
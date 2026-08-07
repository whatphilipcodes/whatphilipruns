#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUADLET_DIR="$HOME/.config/containers/systemd"

mkdir -p "$HOME/postgres"
mkdir -p "$QUADLET_DIR"

if ! podman secret exists postgres_root_password; then
    pwgen -s 32 1 | tr -d '\n' | podman secret create postgres_root_password -
fi

if ! podman secret exists timetracker_app_password; then
    pwgen -s 32 1 | tr -d '\n' | podman secret create timetracker_app_password -
fi

cp -f "$SCRIPT_DIR/init-db.sh" "$HOME/postgres/init-db.sh"
chmod +x "$HOME/postgres/init-db.sh"

systemctl --user stop postgres.service || true

rm -f "$QUADLET_DIR"/postgres.*
rm -f "$QUADLET_DIR"/whatphilipstores.*
rm -f "$QUADLET_DIR"/internal.*

cp -rf "$SCRIPT_DIR/systemd/"* "$QUADLET_DIR/"

systemctl --user daemon-reload
systemctl --user start postgres.service
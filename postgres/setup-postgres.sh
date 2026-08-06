#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUADLET_DIR="$HOME/.config/containers/systemd"

mkdir -p "$HOME/postgres"
mkdir -p "$QUADLET_DIR"

if [ ! -f "$HOME/postgres/.env" ]; then
    POSTGRES_PASSWORD=$(pwgen -s 32 1)

    cat << EOF > "$HOME/postgres/.env"
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
EOF
    chmod 600 "$HOME/postgres/.env"
fi

systemctl --user stop postgres.service || true

rm -f "$QUADLET_DIR"/postgres.*
rm -f "$QUADLET_DIR"/whatphilipstores.*
rm -f "$QUADLET_DIR"/internal.*

cp -rf "$SCRIPT_DIR/systemd/"* "$QUADLET_DIR/"

systemctl --user daemon-reload
systemctl --user start postgres.service
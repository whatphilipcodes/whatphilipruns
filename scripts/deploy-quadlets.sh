#!/bin/bash
set -e

QUADLET_DIR="$HOME/.config/containers/systemd"
REPO_QUADLETS="$HOME/whatphilipruns/quadlets"

mkdir -p "$QUADLET_DIR"

for file in "$REPO_QUADLETS"/*; do
    filename=$(basename "$file")
    ln -sfn "$file" "$QUADLET_DIR/$filename"
done

systemctl --user daemon-reload
systemctl --user enable --now podman-auto-update.timer
systemctl --user restart caddy.service postgres.service timetracker.service vectorizer.service
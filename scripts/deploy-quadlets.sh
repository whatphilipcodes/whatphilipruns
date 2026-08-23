#!/bin/bash
set -e

REPO_QUADLETS="$HOME/whatphilipruns/quadlets"
APP_NAME="whatphilipruns"

bash "$HOME/whatphilipruns/scripts/auth-ghcr.sh"

STAGE_BASE=$(mktemp -d)
trap 'rm -rf "$STAGE_BASE"' EXIT

STAGE_DIR="$STAGE_BASE/$APP_NAME"
mkdir -p "$STAGE_DIR"

SERVICES=()

for file in "$REPO_QUADLETS"/*; do
    filename=$(basename "$file")

    if [[ "$filename" == _* ]]; then
        echo "$filename is prefixed with an underscore. Skipping..."
        continue
    fi

    if [ -f "$file" ]; then
        cp "$file" "$STAGE_DIR/$filename"

        if [[ "$filename" == *.container ]] || [[ "$filename" == *.kube ]] || [[ "$filename" == *.pod ]]; then
            SERVICES+=("${filename%.*}.service")
        fi
    fi
done

podman quadlet rm -f -a
systemctl --user reset-failed
podman quadlet install "$STAGE_DIR"
systemctl --user daemon-reload

if [ ${#SERVICES[@]} -gt 0 ]; then
   systemctl --user start "${SERVICES[@]}"
fi

podman auto-update
systemctl --user enable --now podman-auto-update.timer
systemctl --user list-units --type=service --state=active --no-pager
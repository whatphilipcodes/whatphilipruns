#!/bin/bash
set -e

QUADLET_DIR="$HOME/.config/containers/systemd"
REPO_QUADLETS="$HOME/whatphilipruns/quadlets"

mkdir -p "$QUADLET_DIR"

SERVICES=()

for file in "$REPO_QUADLETS"/*; do
    filename=$(basename "$file")
    
    if [[ "$filename" == _* ]]; then
        echo "$filename is prefixed with an underscore. Skipping..."
        continue
    fi
    
    ln -sfn "$file" "$QUADLET_DIR/$filename"
    
    if [[ "$filename" == *.container ]] || [[ "$filename" == *.kube ]] || [[ "$filename" == *.pod ]]; then
        SERVICES+=("${filename%.*}.service")
    fi
done

systemctl --user daemon-reload
systemctl --user enable --now podman-auto-update.timer

if [ ${#SERVICES[@]} -gt 0 ]; then
    systemctl --user restart "${SERVICES[@]}"
fi
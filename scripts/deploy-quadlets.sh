#!/bin/bash
set -e

QUADLET_DIR="$HOME/.config/containers/systemd"
REPO_QUADLETS="$HOME/whatphilipruns/quadlets"

bash "$HOME/whatphilipruns/scripts/auth-ghcr.sh"

mkdir -p "$QUADLET_DIR"
find "$QUADLET_DIR" -type l -delete

SERVICES=()

for file in "$REPO_QUADLETS"/*; do
    filename=$(basename "$file")
    
    if [[ "$filename" == _* ]]; then
        echo "$filename is prefixed with an underscore. Skipping..."
        continue
    fi
    
    ln -sfnv "$file" "$QUADLET_DIR/$filename"
    
    if [[ "$filename" == *.container ]] || [[ "$filename" == *.kube ]] || [[ "$filename" == *.pod ]]; then
        SERVICES+=("${filename%.*}.service")
    fi
done

systemctl --user daemon-reload
systemctl --user enable --now podman-auto-update.timer

if [ ${#SERVICES[@]} -gt 0 ]; then
    systemctl --user restart "${SERVICES[@]}"
fi

systemctl --user list-units --type=service --state=active --no-pager
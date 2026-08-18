#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/whatphilipruns"

if [ "$SCRIPT_DIR" != "$TARGET_DIR" ]; then
    echo "Repo was not cloned into podman users $HOME. Symlinking..."
    ln -sfnv "$SCRIPT_DIR" "$TARGET_DIR"
fi

if ! podman secret exists postgres_root_password; then
    pwgen -s 32 1 | tr -d '\n' | podman secret create postgres_root_password -
fi

if ! podman secret exists timetracker_app_password; then
    pwgen -s 32 1 | tr -d '\n' | podman secret create timetracker_app_password -
fi

if ! podman secret exists timetracker_api_token; then
    pwgen -s 32 1 | tr -d '\n' | podman secret create timetracker_api_token -
fi

bash "$SCRIPT_DIR/scripts/auth-gh.sh"
bash "$SCRIPT_DIR/scripts/deploy-quadlets.sh"
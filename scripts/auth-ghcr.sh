#!/bin/bash

set +x

GH_USERNAME=$(git config --global user.name)

if ! podman login --get-login ghcr.io >/dev/null 2>&1; then
    if ! podman secret ls --format '{{.Name}}' | grep -q "^ghcr_token$"; then
        printf "Enter GitHub PAT (Classic Token with <packages:read> access only): "
        read -r -s GH_PAT
        printf "\n"
        printf "%s" "$GH_PAT" | podman secret create ghcr_token -
    fi

    if [ -z "$GH_USERNAME" ]; then
        printf "Enter GitHub Username: "
        read -r GH_USERNAME
    fi

    podman login ghcr.io --username "$GH_USERNAME" --secret ghcr_token
fi
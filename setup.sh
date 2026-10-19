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

# Login credential for the single predefined user. Unlike the secrets above this
# is a hash, not a random string, so it cannot be generated with pwgen alone —
# and the app refuses to boot without it (AUTH_PASSWORD_HASH is a required
# astro:env field), which is deliberate: an unconfigured login must never come up
# open.
if ! podman secret exists timetracker_auth_password_hash; then
    if [ -n "${AUTH_PASSWORD_HASH:-}" ]; then
        printf '%s' "$AUTH_PASSWORD_HASH" | podman secret create timetracker_auth_password_hash -
    else
        echo "Missing podman secret 'timetracker_auth_password_hash'." >&2
        echo "On any machine that can pull the image, run:" >&2
        echo '  pw=$(pwgen -s 24 1); printf "password: %s\n" "$pw"; \' >&2
        echo '  printf %s "$pw" | podman run --rm --entrypoint node \' >&2
        echo '    ghcr.io/whatphilipcodes/timetracker:latest /app/bin/hash-password.mjs -; unset pw' >&2
        echo "Write down the printed password — the app can never show it again." >&2
        echo "Then re-run setup.sh with the hash exported as AUTH_PASSWORD_HASH." >&2
        exit 1
    fi
fi

bash "$SCRIPT_DIR/scripts/auth-gh.sh"
bash "$SCRIPT_DIR/scripts/deploy-quadlets.sh"
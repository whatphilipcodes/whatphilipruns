#!/usr/bin/env bash
# Host: copy the whole repo (incl. .git, flake.lock and scripts/) to the server, then run
# scripts/remote-setup.sh there. Needs IP6 in the environment.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
: "${IP6:?}"

echo "Copying repository to $ADMIN_USER@$IP6:~/$REMOTE_REPO_DIR ..."
# .env holds the hcloud token: never ship it. COPYFILE_DISABLE avoids macOS ._* files.
COPYFILE_DISABLE=1 tar --no-xattrs \
  --exclude='./.env' --exclude='./.provision-result' --exclude='./.DS_Store' \
  -C "$ROOT" -cf - . \
  | admin_ssh "mkdir -p '$REMOTE_REPO_DIR' && tar -xf - -C '$REMOTE_REPO_DIR'"

echo "Running remote-setup.sh on the server ..."
admin_ssh "cd '$REMOTE_REPO_DIR/scripts' && bash remote-setup.sh"
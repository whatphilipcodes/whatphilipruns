#!/usr/bin/env bash
# Host: check the few things the host needs.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

command -v podman > /dev/null || die "podman not found"
podman info > /dev/null 2>&1 || die "cannot reach podman (VM not running? try: podman machine start)"
[ -f "$ROOT/.env" ] || die ".env not found in $ROOT"
[ -f "$CONTAINERFILE" ] || die "Containerfile not found: $CONTAINERFILE"
[ -d "$SSH_DIR" ] || die "ssh dir '$SSH_DIR' not found (set SSH_DIR)"
[[ "$REMOTE_REPO_DIR" =~ ^[A-Za-z0-9._-]+$ ]] || die "REMOTE_REPO_DIR must be a simple directory name"
[ -d "$ROOT/.git" ] || echo "warning: no .git directory in $ROOT; the remote copy won't be a git repo" >&2
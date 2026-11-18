#!/usr/bin/env bash
# Orchestrator: runs the steps in scripts/ in order.
#   host:      preflight -> build image -> run container -> verify admin login -> deploy repo
#   container: scripts/container-provision.sh (hcloud + nixos-anywhere)
#   remote:    scripts/remote-setup.sh (copied along with the repo, run on the server)
set -euo pipefail
cd "$(dirname "$0")"
# shellcheck source=scripts/lib.sh
. scripts/lib.sh

trap 'rm -f "$RESULT_FILE"' EXIT
rm -f "$RESULT_FILE"

bash scripts/host-preflight.sh
bash scripts/host-build-image.sh
bash scripts/host-run-container.sh

# No result file = the container aborted cleanly (e.g. answered "N" to the rebuild prompt).
[ -s "$RESULT_FILE" ] || exit 0
set -a && . "$RESULT_FILE" && set +a # SERVER_NAME, IP, IP6

bash scripts/host-verify-admin.sh
bash scripts/host-deploy-repo.sh

echo "Done: $SERVER_NAME is up at $IP / $IP6"
echo "  ssh -p $ADMIN_PORT $ADMIN_USER@$IP6"
echo "  then e.g.: sudo nixos-rebuild dry-activate   (config: ~/$REMOTE_REPO_DIR, linked at /etc/nixos)"
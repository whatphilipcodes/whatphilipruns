# Shared config and helpers for the host and container scripts. Sourced, never executed.
# Keep bash 3.2 compatible (macOS host).
# (remote-setup.sh deliberately does NOT use this: it must stay self-contained.)

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)

# ── Hetzner / target ─────────────────────────────────────────────────────────
TYPE=cax11 # nix flake assumes ARM
LOCATION=fsn1
IMAGE=ubuntu-24.04 # kexec fails on 26.04
ADMIN_USER=philip # nix flake assumes philip
ADMIN_PORT=2222 # firewall expects SSH over 2222
SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o LogLevel=ERROR)

# ── Host-side tooling (overridable from the environment) ─────────────────────
REMOTE_REPO_DIR=${REMOTE_REPO_DIR:-whatphilipruns} # relative to $ADMIN_USER's home
IMAGE_TAG=${IMAGE_TAG:-localhost/hcloud-nixos-provision:latest}
CONTAINERFILE=${CONTAINERFILE:-$ROOT/Containerfile}
NIX_IMAGE=${NIX_IMAGE:-docker.io/nixos/nix:latest}
NIXPKGS_REF=${NIXPKGS_REF:-nixos-26.05} # versions of hcloud/nixos-anywhere in the image
SSH_DIR=${SSH_DIR:-$HOME/.ssh}          # keys the container uses for root@ logins
RESULT_FILE=$ROOT/.provision-result     # container -> host handoff (SERVER_NAME, IP, IP6)

# ── Helpers ──────────────────────────────────────────────────────────────────
die() { echo "error: $*" >&2; exit 1; }

wait_until() {
  local what=$1 timeout=$2 waited=0
  shift 2
  echo "Waiting for $what ..."
  until LAST_OUTPUT=$("$@" 2>&1); do
    waited=$((waited + 3))
    ((waited < timeout)) || die "timed out waiting for $what (last output: ${LAST_OUTPUT:-none})"
    ((waited % 15)) || echo "  ${waited}s: ${LAST_OUTPUT:-still waiting}"
    sleep 3
  done
}

# Needs IP6 in the environment.
admin_ssh() { ssh -6 -p "$ADMIN_PORT" "${SSH_OPTS[@]}" -o BatchMode=yes "$ADMIN_USER@$IP6" "$@"; }
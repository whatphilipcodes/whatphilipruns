#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
set -a && source .env && set +a

# ── Config ───────────────────────────────────────────────────────────────────
TYPE=cax11 # nix flake assumes ARM
LOCATION=fsn1
IMAGE=ubuntu-24.04 # kexec fails on 26.04
ADMIN_USER=philip # nix flake assumes philip
ADMIN_PORT=2222 # firewall expects SSH over 2222
SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o LogLevel=ERROR)

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

# ── Probes ───────────────────────────────────────────────────────────────────
root_ssh_ready() { ssh -p 22 "${SSH_OPTS[@]}" root@"$IP" true; }
admin_port_open() { nc -z -w 5 -6 "$IP6" "$ADMIN_PORT"; }
admin_login() { ssh -6 -p "$ADMIN_PORT" "${SSH_OPTS[@]}" -o BatchMode=yes "$ADMIN_USER@$IP6" true; }

DETACHED_FIREWALLS=()

detach_firewalls() {
  local fw
  read -r -a DETACHED_FIREWALLS < <(hcloud server describe "$HCLOUD_SERVER_NAME" \
    -o format='{{range .PublicNet.Firewalls}}{{.Firewall.ID}} {{end}}')
  for fw in ${DETACHED_FIREWALLS[@]+"${DETACHED_FIREWALLS[@]}"}; do
    echo "Detaching firewall $fw from $HCLOUD_SERVER_NAME ..."
    hcloud firewall remove-from-resource "$fw" --type server --server "$HCLOUD_SERVER_NAME"
  done
}

restore_firewalls() {
  local fw
  for fw in ${DETACHED_FIREWALLS[@]+"${DETACHED_FIREWALLS[@]}"}; do
    echo "Re-attaching firewall $fw to $HCLOUD_SERVER_NAME ..."
    hcloud firewall apply-to-resource "$fw" --type server --server "$HCLOUD_SERVER_NAME" \
      || echo "warning: could not re-attach firewall $fw, do it manually" >&2
  done
  DETACHED_FIREWALLS=()
}

# ── Cloud-init ───────────────────────────────────────────────────────────────
render_user_data() {
  local pubkey
  pubkey=$(hcloud ssh-key describe "$HCLOUD_SSH_KEY_ID" -o format='{{.PublicKey}}')
  [ -n "$pubkey" ] || die "could not read public key for ssh key '$HCLOUD_SSH_KEY_ID'"
  cat << CLOUDCFG
#cloud-config
disable_root: false
ssh_pwauth: false
users:
  - name: root
    ssh_authorized_keys:
      - ${pubkey}
CLOUDCFG
}

# ── Server lifecycle ─────────────────────────────────────────────────────────
server_exists() { hcloud server describe "$HCLOUD_SERVER_NAME" >/dev/null 2>&1; }

confirm_rebuild() {
  local answer=""
  echo "Server '$HCLOUD_SERVER_NAME' already exists ($(hcloud server ip "$HCLOUD_SERVER_NAME"))."
  read -r -p "Rebuild it from $IMAGE? This ERASES everything on it. [y/N] " answer || true
  [[ "$answer" =~ ^([yY]|[yY][eE][sS])$ ]]
}

provision_server() {
  if server_exists; then
    confirm_rebuild || { echo "Aborted."; exit 0; }
    detach_firewalls
    hcloud server rebuild "$HCLOUD_SERVER_NAME" --image "$IMAGE" --user-data-from-file "$USER_DATA"
  else
    hcloud server create \
      --name "$HCLOUD_SERVER_NAME" --type "$TYPE" --location "$LOCATION" \
      --image "$IMAGE" --ssh-key "$HCLOUD_SSH_KEY_ID" \
      --user-data-from-file "$USER_DATA"
  fi
}

resolve_ips() {
  IP=$(hcloud server ip "$HCLOUD_SERVER_NAME")
  IP6=$(hcloud server ip -6 "$HCLOUD_SERVER_NAME")
  IP6=${IP6%%/*}
  [ -n "$IP6" ] || die "could not determine IPv6 address of $HCLOUD_SERVER_NAME"
  [[ "$IP6" == *:: ]] && IP6="${IP6}1"
  return 0
}

forget_host_keys() {
  local host
  for host in "[${IP}]:${ADMIN_PORT}" "$IP" "[${IP6}]:${ADMIN_PORT}"; do
    ssh-keygen -R "$host" 2>/dev/null || true
  done
}

install_nixos() {
  nix run github:NixOS/nixpkgs/nixpkgs-26.05-darwin#nixos-anywhere -- \
    --flake "path:.#$HCLOUD_SERVER_NAME" \
    --build-on remote \
    --target-host root@"$IP"
}

verify_admin_login() {
  echo "Port $ADMIN_PORT is open on $IP6, trying one login ..."
  local err
  err=$(admin_login 2>&1) \
    || die "sshd is up but login failed (not retrying, to avoid fail2ban): $err
Hint: if this says 'Too many authentication failures', set IdentitiesOnly and -i for your key."
}

# ── Main ─────────────────────────────────────────────────────────────────────
USER_DATA=$(mktemp)
trap 'rm -f "$USER_DATA"; restore_firewalls' EXIT
render_user_data > "$USER_DATA"

provision_server
resolve_ips
forget_host_keys

wait_until "root@$IP:22" 300 root_ssh_ready
install_nixos
restore_firewalls

wait_until "$IP6:$ADMIN_PORT" 300 admin_port_open
verify_admin_login

echo "Done: $HCLOUD_SERVER_NAME is up at $IP / $IP6 (ssh -p $ADMIN_PORT $ADMIN_USER@$IP6)"
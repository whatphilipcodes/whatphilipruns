#!/usr/bin/env bash
# Container (linux/arm64): create/rebuild the Hetzner server and install NixOS.
# Writes $RESULT_FILE (SERVER_NAME, IP, IP6) for the host steps that follow.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -a && source .env && set +a # before lib.sh, so the config there wins
# shellcheck source=lib.sh
. scripts/lib.sh

root_ssh_ready() { ssh -p 22 "${SSH_OPTS[@]}" root@"$IP" true; }

# Host ~/.ssh is mounted read-only; copy the private keys into the container's
# own ~/.ssh (correct perms, no macOS-only config options like UseKeychain) and
# pin ssh to exactly those keys.
setup_ssh() {
  local key
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  cp -R /host-ssh/. ~/.ssh/ 2> /dev/null || true
  rm -f ~/.ssh/config ~/.ssh/known_hosts ~/.ssh/known_hosts.old
  printf 'Host *\n  IdentitiesOnly yes\n' > ~/.ssh/config
  for key in ~/.ssh/*; do
    [ -f "$key" ] && grep -qs -- 'PRIVATE KEY-----' "$key" || continue
    chmod 600 "$key"
    printf '  IdentityFile %s\n' "$key" >> ~/.ssh/config
  done
}

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

server_exists() { hcloud server describe "$HCLOUD_SERVER_NAME" > /dev/null 2>&1; }

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

install_nixos() {
  nixos-anywhere \
    --flake "path:.#$HCLOUD_SERVER_NAME" \
    --build-on remote \
    --target-host root@"$IP"
}

write_result() {
  cat > "$RESULT_FILE" << RESULT
SERVER_NAME=$HCLOUD_SERVER_NAME
IP=$IP
IP6=$IP6
RESULT
}

setup_ssh

USER_DATA=$(mktemp)
trap 'rm -f "$USER_DATA"; restore_firewalls' EXIT
render_user_data > "$USER_DATA"

provision_server
resolve_ips

wait_until "root@$IP:22" 300 root_ssh_ready
install_nixos
restore_firewalls

write_result
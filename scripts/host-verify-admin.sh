#!/usr/bin/env bash
# Host: wait for the admin sshd (IPv6) and verify one login.
# Needs IP, IP6 in the environment (set by init.sh from the container's result file).
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
: "${IP:?}" "${IP6:?}"

admin_port_open() { nc -z -w 5 -6 "$IP6" "$ADMIN_PORT"; }

# Clean the host's real known_hosts, so manual ssh to the rebuilt server doesn't complain.
for host in "[${IP}]:${ADMIN_PORT}" "$IP" "[${IP6}]:${ADMIN_PORT}"; do
  ssh-keygen -R "$host" > /dev/null 2>&1 || true
done

wait_until "$IP6:$ADMIN_PORT" 300 admin_port_open

echo "Port $ADMIN_PORT is open on $IP6, trying one login ..."
err=$(admin_ssh true 2>&1) \
  || die "sshd is up but login failed (not retrying, to avoid fail2ban): $err
Hint: if this says 'Too many authentication failures', set IdentitiesOnly and -i for your key."
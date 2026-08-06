#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

apt-get update
apt-get install -y podman gettext-base pwgen systemd-container htop

id -u podman &>/dev/null || useradd -m -u 1001 -s /bin/bash podman
PODMAN_UID=$(id -u podman)

echo "net.ipv4.ip_unprivileged_port_start=80" > /etc/sysctl.d/99-podman-ports.conf
sysctl --system

loginctl enable-linger podman
systemctl start "user@${PODMAN_UID}.service"

systemd-run --machine=podman@.host --user --wait --quiet /bin/bash "$SCRIPT_DIR/postgres/setup-postgres.sh"
systemd-run --machine=podman@.host --user --wait --quiet /bin/bash "$SCRIPT_DIR/caddy/setup-caddy.sh"
systemd-run --machine=podman@.host --user --wait --quiet /bin/bash "$SCRIPT_DIR/timetracker/setup-timetracker.sh"
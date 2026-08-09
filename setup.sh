#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

apt-get update
apt-get install -y podman gettext-base pwgen systemd-container htop gh

id -u podman &>/dev/null || useradd -m -u 1001 -s /bin/bash podman
PODMAN_UID=$(id -u podman)

echo "net.ipv4.ip_unprivileged_port_start=80" > /etc/sysctl.d/99-podman-ports.conf
sysctl --system

loginctl enable-linger podman
systemctl start "user@${PODMAN_UID}.service"

sleep 2

TEMP_PODMAN_DIR="/home/podman/temp-whatphilipruns"
rm -rf "$TEMP_PODMAN_DIR"
cp -r "$SCRIPT_DIR" "$TEMP_PODMAN_DIR"
chown -R podman:podman "$TEMP_PODMAN_DIR"

systemd-run --machine=podman@.host --user --pipe --wait /bin/bash "$TEMP_PODMAN_DIR/postgres/setup-postgres.sh"
systemd-run --machine=podman@.host --user --pipe --wait /bin/bash "$TEMP_PODMAN_DIR/caddy/setup-caddy.sh"
systemd-run --machine=podman@.host --user --pipe --wait /bin/bash "$TEMP_PODMAN_DIR/timetracker/setup-timetracker.sh"
systemd-run --machine=podman@.host --user --pipe --wait /bin/bash "$TEMP_PODMAN_DIR/vectorizer/setup-vectorizer.sh"

rm -rf "$TEMP_PODMAN_DIR"

echo "SETUP COMPLETE"
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

apt-get update
apt-get install -y podman gettext-base pwgen systemd-container htop gh git

id -u podman &>/dev/null || useradd -m -u 1001 -s /bin/bash podman
PODMAN_UID=$(id -u podman)

echo "net.ipv4.ip_unprivileged_port_start=80" > /etc/sysctl.d/99-podman-ports.conf
sysctl --system

loginctl enable-linger podman
systemctl start "user@${PODMAN_UID}.service"
sleep 2

REPO_DIR="/home/podman/whatphilipruns"
if [ ! -d "$REPO_DIR" ]; then
    cp -r "$SCRIPT_DIR" "$REPO_DIR"
    chown -R podman:podman "$REPO_DIR"
fi

systemd-run --machine=podman@.host --user --pipe --wait /bin/bash -c "
    if ! podman secret exists postgres_root_password; then
        pwgen -s 32 1 | tr -d '\n' | podman secret create postgres_root_password -
    fi
    if ! podman secret exists timetracker_app_password; then
        pwgen -s 32 1 | tr -d '\n' | podman secret create timetracker_app_password -
    fi
    if ! podman secret exists timetracker_api_token; then
        pwgen -s 32 1 | tr -d '\n' | podman secret create timetracker_api_token -
    fi
    bash /home/podman/whatphilipruns/scripts/deploy-quadlets.sh
"
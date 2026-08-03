#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p /home/podman/postgres

if [ ! -f /home/podman/postgres/.env ]; then
    POSTGRES_PASSWORD=$(pwgen -s 32 1)

    cat << EOF > /home/podman/postgres/.env
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
EOF
    chmod 600 /home/podman/postgres/.env
fi

su - podman -c "XDG_RUNTIME_DIR=/run/user/1001 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus systemctl --user stop postgres.service || true"

rm -f /etc/containers/systemd/users/1001/postgres.*
rm -f /etc/containers/systemd/users/1001/whatphilipstores.*
rm -f /etc/containers/systemd/users/1001/internal.*

cp -rf "$SCRIPT_DIR/systemd/"* /etc/containers/systemd/users/1001/

chown -R podman:podman /home/podman/postgres

su - podman -c "XDG_RUNTIME_DIR=/run/user/1001 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus systemctl --user daemon-reload"
su - podman -c "XDG_RUNTIME_DIR=/run/user/1001 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus systemctl --user start postgres.service"
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! su - podman -c "podman image exists timetracker:latest"; then
    echo "WARNING: Image 'timetracker:latest' not found in the local registry."
    echo "Skipping timetracker setup. Please build and push the image via SSH."
    exit 0
fi

mkdir -p /home/podman/timetracker

if [ ! -f /home/podman/timetracker/.env ]; then
    export $(xargs < /home/podman/postgres/.env)
    DATABASE_URL="postgresql://timetracker:${PW_TIMETRACKER}@systemd-postgres:5432/postgres?schema=timetracking"

    cat << EOF > /home/podman/timetracker/.env
DATABASE_URL=${DATABASE_URL}
EOF
    chmod 600 /home/podman/timetracker/.env
fi

su - podman -c "XDG_RUNTIME_DIR=/run/user/1001 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus systemctl --user stop timetracker.service || true"

rm -f /etc/containers/systemd/users/1001/timetracker.*

cp -rf "$SCRIPT_DIR/systemd/"* /etc/containers/systemd/users/1001/

chown -R podman:podman /home/podman/timetracker

su - podman -c "XDG_RUNTIME_DIR=/run/user/1001 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus systemctl --user daemon-reload"
su - podman -c "XDG_RUNTIME_DIR=/run/user/1001 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus systemctl --user start timetracker.service"
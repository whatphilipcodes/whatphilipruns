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
    PW_TIMETRACKER=$(pwgen -s 32 1)
    DATABASE_URL="postgresql://timetracker:${PW_TIMETRACKER}@systemd-postgres:5432/whatphilipstores_db?schema=timetracking"

    cat << EOF > /home/podman/timetracker/.env
PW_TIMETRACKER=${PW_TIMETRACKER}
DATABASE_URL=${DATABASE_URL}
EOF
    chmod 600 /home/podman/timetracker/.env
fi

export $(xargs < /home/podman/timetracker/.env)

su - podman -c "until podman exec systemd-postgres pg_isready -U postgres; do sleep 1; done"

su - podman -c "podman exec -i systemd-postgres psql -U postgres -tc \"SELECT 1 FROM pg_roles WHERE rolname='timetracker'\" | grep -q 1 || podman exec -i systemd-postgres psql -U postgres -c \"CREATE USER timetracker WITH ENCRYPTED PASSWORD '${PW_TIMETRACKER}';\""

su - podman -c "podman exec -i systemd-postgres psql -U postgres -tc \"SELECT 1 FROM pg_database WHERE datname='whatphilipstores_db'\" | grep -q 1 || podman exec -i systemd-postgres psql -U postgres -c \"CREATE DATABASE whatphilipstores_db;\""

su - podman -c "podman exec -i systemd-postgres psql -U postgres -d whatphilipstores_db -c \"CREATE SCHEMA IF NOT EXISTS timetracking AUTHORIZATION timetracker; ALTER USER timetracker SET search_path TO timetracking; GRANT CONNECT ON DATABASE whatphilipstores_db TO timetracker; GRANT ALL ON SCHEMA timetracking TO timetracker;\""

su - podman -c "XDG_RUNTIME_DIR=/run/user/1001 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus systemctl --user stop timetracker.service || true"

rm -f /etc/containers/systemd/users/1001/timetracker.*

cp -rf "$SCRIPT_DIR/systemd/"* /etc/containers/systemd/users/1001/

chown -R podman:podman /home/podman/timetracker

su - podman -c "XDG_RUNTIME_DIR=/run/user/1001 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus systemctl --user daemon-reload"
su - podman -c "XDG_RUNTIME_DIR=/run/user/1001 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus systemctl --user start timetracker.service"
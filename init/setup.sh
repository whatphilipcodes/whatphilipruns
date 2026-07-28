#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

apt-get update
apt-get install -y podman gettext-base pwgen

id -u podman &>/dev/null || useradd -m -u 1001 -s /bin/bash podman

echo "net.ipv4.ip_unprivileged_port_start=80" > /etc/sysctl.d/99-podman-ports.conf
sysctl --system

mkdir -p /etc/containers/systemd/users/1001
mkdir -p /home/podman/caddy
mkdir -p /home/podman/postgres-init

export POSTGRES_PASSWORD=$(pwgen -s 32 1)
export PW_TIMETRACKER=$(pwgen -s 32 1)

cat << EOF > /home/podman/.env
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
PW_TIMETRACKER=${PW_TIMETRACKER}
EOF

chown podman:podman /home/podman/.env
chmod 600 /home/podman/.env

cp -r "$SCRIPT_DIR/systemd/"* /etc/containers/systemd/users/1001/
cp "$SCRIPT_DIR/caddy/Caddyfile" /home/podman/caddy/Caddyfile

envsubst < "$SCRIPT_DIR/postgres/init-schemas.sql.template" > /home/podman/postgres-init/init-schemas.sql

chown -R podman:podman /home/podman/caddy
chown -R podman:podman /home/podman/postgres-init

loginctl enable-linger podman
systemctl start user@1001.service

sleep 1

sysctl --system

su - podman -c "XDG_RUNTIME_DIR=/run/user/1001 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus systemctl --user daemon-reload"
su - podman -c "XDG_RUNTIME_DIR=/run/user/1001 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus systemctl --user start caddy.service postgres.service"
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p /home/podman/caddy

cp -f "$SCRIPT_DIR/Caddyfile" /home/podman/caddy/Caddyfile

su - podman -c "XDG_RUNTIME_DIR=/run/user/1001 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus systemctl --user stop caddy.service || true"

rm -f /etc/containers/systemd/users/1001/caddy.*
rm -f /etc/containers/systemd/users/1001/caddy_*
rm -f /etc/containers/systemd/users/1001/web.*

cp -rf "$SCRIPT_DIR/systemd/"* /etc/containers/systemd/users/1001/

chown -R podman:podman /home/podman/caddy

su - podman -c "XDG_RUNTIME_DIR=/run/user/1001 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus systemctl --user daemon-reload"
su - podman -c "XDG_RUNTIME_DIR=/run/user/1001 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus systemctl --user start caddy.service"
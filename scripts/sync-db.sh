#!/bin/bash
set -e

ACTION="$1"
VPS_HOST="${2:-philip@whatphilipruns}"
VPS_PORT="${3:-2222}"

if [ "$ACTION" = "pull" ]; then
    ssh -p "$VPS_PORT" "$VPS_HOST" "sudo machinectl shell podman@ /usr/bin/podman exec systemd-postgres pg_dump -U postgres whatphilipstores_db" | podman exec -i local-postgres psql -U postgres -d whatphilipstores_db
elif [ "$ACTION" = "push" ]; then
    echo "CONFIRM: Overwrite production database with local state? (y/N)"
    read -r CONFIRMATION
    if [ "$CONFIRMATION" != "y" ]; then
        echo "Aborted."
        exit 1
    fi
    podman exec local-postgres pg_dump -U postgres whatphilipstores_db | ssh -p "$VPS_PORT" "$VPS_HOST" "sudo machinectl shell podman@ /usr/bin/podman exec -i systemd-postgres psql -U postgres -d whatphilipstores_db"
else
    echo "Usage: $0 [pull|push] [user@host] [port]"
    exit 1
fi
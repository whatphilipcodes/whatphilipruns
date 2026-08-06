#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUADLET_DIR="$HOME/.config/containers/systemd"

if ! podman image exists timetracker:latest; then
    exit 0
fi

mkdir -p "$HOME/timetracker"
mkdir -p "$QUADLET_DIR"

if [ ! -f "$HOME/timetracker/.env" ] || [ ! -f "$HOME/timetracker/.env.migration" ]; then
    . "$HOME/postgres/.env"

    PW_TIMETRACKER=$(pwgen -s 32 1)

    cat << EOF > "$HOME/timetracker/.env"
DB_HOST=systemd-postgres
DB_NAME=whatphilipstores_db
DB_PORT=5432
DB_SCHEMA=timetracking
DB_USER_APP=timetracker
DB_PASSWORD_APP=${PW_TIMETRACKER}
DB_USER_MIGRATION=dummy
DB_PASSWORD_MIGRATION=notapassword
EOF
    chmod 600 "$HOME/timetracker/.env"

    cat << EOF > "$HOME/timetracker/.env.migration"
DB_HOST=systemd-postgres
DB_NAME=whatphilipstores_db
DB_PORT=5432
DB_SCHEMA=timetracking
DB_USER_MIGRATION=postgres
DB_PASSWORD_MIGRATION=${POSTGRES_PASSWORD}
EOF
    chmod 600 "$HOME/timetracker/.env.migration"
fi

. "$HOME/timetracker/.env"

until podman exec systemd-postgres pg_isready -U postgres; do sleep 1; done

if ! podman exec -i systemd-postgres psql -U postgres -tc "SELECT 1 FROM pg_roles WHERE rolname='timetracker'" | grep -q 1; then
    echo "CREATE USER timetracker WITH ENCRYPTED PASSWORD '${DB_PASSWORD_APP}';" | podman exec -i systemd-postgres psql -U postgres
fi

echo "ALTER USER timetracker WITH ENCRYPTED PASSWORD '${DB_PASSWORD_APP}';" | podman exec -i systemd-postgres psql -U postgres

if ! podman exec -i systemd-postgres psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname='whatphilipstores_db'" | grep -q 1; then
    podman exec -i systemd-postgres psql -U postgres -c "CREATE DATABASE whatphilipstores_db;"
fi

podman exec -i systemd-postgres psql -U postgres -d whatphilipstores_db -c "CREATE SCHEMA IF NOT EXISTS timetracking AUTHORIZATION timetracker; ALTER USER timetracker SET search_path TO timetracking; GRANT CONNECT ON DATABASE whatphilipstores_db TO timetracker; GRANT ALL ON SCHEMA timetracking TO timetracker; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA timetracking TO timetracker; GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA timetracking TO timetracker; ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA timetracking GRANT ALL PRIVILEGES ON TABLES TO timetracker; ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA timetracking GRANT ALL PRIVILEGES ON SEQUENCES TO timetracker;"

systemctl --user stop timetracker.service || true

rm -f "$QUADLET_DIR"/timetracker.*

cp -rf "$SCRIPT_DIR/systemd/"* "$QUADLET_DIR/"

systemctl --user daemon-reload
systemctl --user start timetracker.service
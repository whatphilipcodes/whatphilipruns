#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'timetracker') THEN
            CREATE USER timetracker WITH ENCRYPTED PASSWORD '$DB_PASSWORD_APP';
        END IF;
    END
    \$\$;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -tc "SELECT 1 FROM pg_database WHERE datname = 'whatphilipstores_db'" | grep -q 1 || psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE DATABASE whatphilipstores_db;"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "whatphilipstores_db" <<-EOSQL
    CREATE SCHEMA IF NOT EXISTS timetracking AUTHORIZATION timetracker;
    ALTER USER timetracker SET search_path TO timetracking;
    GRANT CONNECT ON DATABASE whatphilipstores_db TO timetracker;
    GRANT ALL ON SCHEMA timetracking TO timetracker;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA timetracking TO timetracker;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA timetracking TO timetracker;
    ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA timetracking GRANT ALL PRIVILEGES ON TABLES TO timetracker;
    ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA timetracking GRANT ALL PRIVILEGES ON SEQUENCES TO timetracker;
EOSQL
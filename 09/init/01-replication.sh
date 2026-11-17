#!/bin/sh
set -eu
psql -X -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<'SQL'
CREATE ROLE replicator WITH LOGIN REPLICATION PASSWORD 'replica_lab';
SQL
printf '\nhost replication replicator all scram-sha-256\n' >> "$PGDATA/pg_hba.conf"

#!/bin/sh
set -eu
if [ -s "$PGDATA/PG_VERSION" ] || [ -e "$PGDATA/standby.signal" ]; then
  echo 'Каталог реплики уже содержит PostgreSQL. Используйте start-replica.' >&2
  exit 1
fi
mkdir -p "$PGDATA"
if [ -n "$(ls -A "$PGDATA")" ]; then
  echo 'Каталог реплики не пуст. Начальная копия не будет его перезаписывать.' >&2
  exit 1
fi
chown postgres:postgres "$PGDATA"
chmod 700 "$PGDATA"
gosu postgres pg_basebackup \
  -d 'host=primary port=5432 user=replicator password=replica_lab application_name=pg09_replica' \
  -D "$PGDATA" -X stream -R --checkpoint=fast --progress

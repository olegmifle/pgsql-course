#!/bin/sh
set -eu
if [ ! -s "$PGDATA/PG_VERSION" ] || [ ! -e "$PGDATA/standby.signal" ]; then
  echo 'Реплика ещё не подготовлена. Выполните: sh lab.sh init-replica' >&2
  exit 1
fi
exec /usr/local/bin/docker-entrypoint.sh "$@"

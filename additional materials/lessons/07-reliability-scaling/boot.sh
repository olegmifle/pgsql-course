#!/bin/sh
set -eu
BASE=/tmp/course07
mkdir -p "$BASE/archive"
if [ ! -f "$BASE/primary/PG_VERSION" ]; then
  initdb -D "$BASE/primary" -U course -A trust --no-locale -E UTF8 >/dev/null
  cat >> "$BASE/primary/postgresql.conf" <<'CONF'
port=5540
listen_addresses='127.0.0.1'
unix_socket_directories='/tmp/course07'
wal_level=replica
max_wal_senders=10
max_replication_slots=10
archive_mode=on
archive_command='test -f /tmp/course07/archive/%f || cp %p /tmp/course07/archive/%f'
timezone='UTC'
CONF
  pg_ctl -D "$BASE/primary" -l "$BASE/primary.log" -w start
  createdb -h 127.0.0.1 -p 5540 -U course course_lesson07
  psql -X -h 127.0.0.1 -p 5540 -U course -d course_lesson07 -v ON_ERROR_STOP=1 -f /work/prepare.sql >/dev/null
  pg_basebackup -h 127.0.0.1 -p 5540 -U course -D "$BASE/basebackup" -X stream --checkpoint=fast
  pg_verifybackup "$BASE/basebackup" > "$BASE/backup-verification.txt"
  pg_basebackup -h 127.0.0.1 -p 5540 -U course -D "$BASE/replica" -X stream -R --checkpoint=fast
  cat >> "$BASE/replica/postgresql.auto.conf" <<'CONF'
port=5541
archive_mode=off
primary_conninfo='host=127.0.0.1 port=5540 user=course application_name=lesson07_replica'
CONF
else
  pg_ctl -D "$BASE/primary" -l "$BASE/primary.log" -w start
fi
pg_ctl -D "$BASE/replica" -l "$BASE/replica.log" -w start
pgbouncer -d /work/pgbouncer.ini
touch "$BASE/ready"
trap 'pg_ctl -D /tmp/course07/replica -m fast stop; pg_ctl -D /tmp/course07/primary -m fast stop; exit 0' TERM INT
while :; do sleep 30 & wait $! || true; done

#!/bin/sh
set -eu
DATA=/var/lib/postgresql/hw07
DB=course_hw07
mkdir -p "$DATA/archive"
rm -f "$DATA/ready"
psql_main() { psql -X -q -h 127.0.0.1 -p 5540 -U course -d "$DB" -v ON_ERROR_STOP=1 "$@"; }
stop_all() {
  for node in restored r2 r1 subscriber primary; do
    if [ -f "$DATA/$node/PG_VERSION" ]; then
      pg_ctl -D "$DATA/$node" -m fast -w stop >/dev/null 2>&1 || true
    fi
  done
  exit 0
}
trap stop_all TERM INT
if [ ! -f "$DATA/primary/PG_VERSION" ]; then
  initdb -D "$DATA/primary" -U course -A trust --no-locale -E UTF8 >/dev/null
  cat >> "$DATA/primary/postgresql.conf" <<'CONF'
port=5540
listen_addresses='127.0.0.1'
unix_socket_directories='/var/lib/postgresql/hw07'
wal_level=logical
max_wal_senders=12
max_replication_slots=12
archive_mode=on
archive_command='sh /work/lab/archive.sh %p %f'
timezone='UTC'
shared_buffers='48MB'
max_connections=30
log_error_verbosity=verbose
CONF
fi
pg_ctl -D "$DATA/primary" -l "$DATA/primary.log" -w start
if ! psql -X -qAt -h 127.0.0.1 -p 5540 -U course -d postgres -c "SELECT 1 FROM pg_database WHERE datname='$DB'" | grep -q 1; then
  createdb -h 127.0.0.1 -p 5540 -U course "$DB"
  psql_main -f /work/schema.sql -f /work/seed.sql
fi
for node in r1 r2; do
  case "$node" in r1) port=5541;; r2) port=5543;; esac
  if [ ! -f "$DATA/$node/PG_VERSION" ]; then
    pg_basebackup -h 127.0.0.1 -p 5540 -U course -D "$DATA/$node" -R -X stream --checkpoint=fast
    cat >> "$DATA/$node/postgresql.auto.conf" <<CONF
port=$port
archive_mode=off
primary_conninfo='host=127.0.0.1 port=5540 user=course application_name=hw07_$node'
CONF
  fi
  pg_ctl -D "$DATA/$node" -l "$DATA/$node.log" -w start
done
if [ ! -f "$DATA/subscriber/PG_VERSION" ]; then
  initdb -D "$DATA/subscriber" -U course -A trust --no-locale -E UTF8 >/dev/null
  cat >> "$DATA/subscriber/postgresql.conf" <<'CONF'
port=5544
listen_addresses='127.0.0.1'
unix_socket_directories='/var/lib/postgresql/hw07'
timezone='UTC'
shared_buffers='48MB'
max_connections=30
log_error_verbosity=verbose
wal_retrieve_retry_interval='200ms'
CONF
fi
pg_ctl -D "$DATA/subscriber" -l "$DATA/subscriber.log" -w start
if ! psql -X -qAt -h 127.0.0.1 -p 5544 -U course -d postgres -c "SELECT 1 FROM pg_database WHERE datname='$DB'" | grep -q 1; then
  createdb -h 127.0.0.1 -p 5544 -U course "$DB"
  psql -X -q -h 127.0.0.1 -p 5544 -U course -d "$DB" -v ON_ERROR_STOP=1 -f /work/lab/subscriber.sql
  psql -X -q -h 127.0.0.1 -p 5544 -U course -d "$DB" -v ON_ERROR_STOP=1 -c "CREATE SUBSCRIPTION hw07_sub CONNECTION 'host=127.0.0.1 port=5540 user=course dbname=$DB application_name=hw07_sub' PUBLICATION hw07_pub"
fi
if [ ! -f "$DATA/initialized" ]; then
  n=0
  until [ "$(psql -X -qAt -h 127.0.0.1 -p 5544 -U course -d "$DB" -c "SELECT count(*) FROM pg_subscription_rel WHERE srsubstate='r'")" = 3 ]; do
    n=$((n+1)); [ "$n" -le 150 ] || { echo 'Initial copy did not finish' >&2; exit 1; }
    sleep .2
  done
  if [ ! -f "$DATA/basebackup/PG_VERSION" ]; then
    pg_basebackup -h 127.0.0.1 -p 5540 -U course -D "$DATA/basebackup" -X stream --checkpoint=fast
  fi
  pg_verifybackup "$DATA/basebackup" > "$DATA/backup-verification.txt"
  touch "$DATA/initialized"
fi
if [ -f "$DATA/restored/PG_VERSION" ]; then
  pg_ctl -D "$DATA/restored" -l "$DATA/restored.log" -w start
fi
touch "$DATA/ready"
echo 'Ready: primary=5540 r1=5541 r2=5543 subscriber=5544; database course_hw07'
while :; do sleep 5 & wait $! || true; done

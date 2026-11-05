#!/bin/sh
set -eu
DATA=/var/lib/postgresql/hw07
DB=course_hw07
port_of() {
  case "$1" in primary) echo 5540;; r1) echo 5541;; r2) echo 5543;; subscriber) echo 5544;; restored) echo 5545;;
    *) echo 'Node: primary | r1 | r2 | subscriber | restored' >&2; exit 2;; esac
}
sql() { node=$1; shift; psql -X -qAt -h 127.0.0.1 -p "$(port_of "$node")" -U course -d "$DB" -v ON_ERROR_STOP=1 "$@"; }
action=${1:-help}
case "$action" in
  psql)
    node=${2:-primary}; shift 2
    exec psql -X -h 127.0.0.1 -p "$(port_of "$node")" -U course -d "$DB" -v ON_ERROR_STOP=1 "$@"
    ;;
  pause|resume)
    node=${2:-}; case "$node" in r1|r2) ;; *) echo 'Use r1 or r2' >&2; exit 2;; esac
    if [ "$action" = pause ]; then
      sql "$node" -c 'SELECT pg_wal_replay_pause()'
      n=0
      until [ "$(sql "$node" -c 'SELECT pg_get_wal_replay_pause_state()')" = paused ]; do
        n=$((n+1)); [ "$n" -le 100 ] || exit 1; sleep .1
      done
    else sql "$node" -c 'SELECT pg_wal_replay_resume()'; fi
    ;;
  sync)
    case "${2:-}" in async) value='';; any1) value='ANY 1 (hw07_r1, hw07_r2)';; any2) value='ANY 2 (hw07_r1, hw07_r2)';;
      *) echo 'sync async | any1 | any2' >&2; exit 2;; esac
    sql primary -c "ALTER SYSTEM SET synchronous_standby_names='$value'"
    sql primary -c 'SELECT pg_reload_conf()' >/dev/null
    n=0
    until [ "$(sql primary -c 'SHOW synchronous_standby_names')" = "$value" ]; do
      n=$((n+1)); [ "$n" -le 50 ] || exit 1; sleep .1
    done
    ;;
  fixture)
    case "${2:-}" in missing|conflict|ddl|fk) file=$2;; *) echo 'fixture missing | conflict | ddl | fk' >&2; exit 2;; esac
    sql primary -f "/work/fixtures/02-$file.sql"
    ;;
  snapshot)
    node=${2:-}; table=${3:-orders}
    case "$table" in orders) relation=hw07.orders; ordering=o.id;; items) relation=hw07.order_items; ordering=o.order_id,o.line_no;; *) exit 2;; esac
    # One JSON column in CSV preserves every source column, including later DDL.
    sql "$node" -c "SET TIME ZONE 'UTC'; COPY (SELECT to_jsonb(o) FROM $relation o ORDER BY $ordering) TO STDOUT WITH (FORMAT csv,HEADER true)"
    ;;
  incident)
    [ "$(sql primary -c "SELECT count(*) FROM hw07.lab_state WHERE name='incident'")" = 0 ] || { echo 'Incident already created. Use a fresh Compose project for another attempt.' >&2; exit 2; }
    sql primary -f /work/fixtures/03-before.sql
    sql primary -c "SELECT pg_create_restore_point('hw07_before_delete')"
    sql primary -f /work/fixtures/03-after.sql
    segment=$(sql primary -c 'SELECT pg_walfile_name(pg_current_wal_insert_lsn())')
    sql primary -c 'SELECT pg_switch_wal()' >/dev/null
    n=0
    until [ -f "$DATA/archive/$segment" ] && [ -f "$DATA/primary/pg_wal/archive_status/$segment.done" ]; do
      n=$((n+1)); [ "$n" -le 200 ] || { echo 'WAL was not archived' >&2; exit 1; }; sleep .1
    done
    echo 'Target: hw07_before_delete; incident committed and WAL archived.'
    ;;
  recover)
    [ ! -e "$DATA/restored" ] || { echo 'Restored directory already exists; it has not been overwritten.' >&2; exit 2; }
    pg_verifybackup "$DATA/basebackup"
    cp -a "$DATA/basebackup" "$DATA/restored"
    cat >> "$DATA/restored/postgresql.auto.conf" <<'CONF'
port=5545
archive_mode=off
primary_conninfo=''
restore_command='cp /var/lib/postgresql/hw07/archive/%f %p'
recovery_target_name='hw07_before_delete'
recovery_target_action='pause'
CONF
    touch "$DATA/restored/recovery.signal"
    pg_ctl -D "$DATA/restored" -l "$DATA/restored.log" -w start
    n=0
    until [ "$(sql restored -c 'SELECT pg_is_wal_replay_paused()' 2>/dev/null || true)" = t ]; do
      n=$((n+1)); [ "$n" -le 200 ] || { tail -20 "$DATA/restored.log" >&2; exit 1; }; sleep .1
    done
    echo 'Restored is paused at hw07_before_delete, port 5545. Primary is still running.'
    ;;
  status)
    sql primary -c "SELECT application_name,state,sync_state,write_lsn,flush_lsn,replay_lsn FROM pg_stat_replication ORDER BY application_name"
    sql subscriber -c 'SELECT subname,apply_error_count,confl_update_missing,confl_insert_exists FROM pg_stat_subscription_stats'
    ;;
  log)
    node=${2:-primary}; port_of "$node" >/dev/null; tail -60 "$DATA/$node.log"
    ;;
  *) echo 'psql NODE [psql-options] | pause r1/r2 | resume r1/r2 | sync async/any1/any2'
     echo 'fixture missing/conflict/ddl/fk | snapshot NODE orders/items | incident | recover | status | log NODE'
     ;;
esac

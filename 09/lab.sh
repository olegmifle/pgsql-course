#!/bin/sh
set -eu
LAB_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PG09_PROJECT_NAME=${PG09_PROJECT_NAME:-pg09-telemetry}
dc() { docker compose --project-name "$PG09_PROJECT_NAME" --project-directory "$LAB_DIR" -f "$LAB_DIR/compose.yaml" "$@"; }
sql_primary() { dc exec -T primary psql -X -U postgres -d telemetry -v ON_ERROR_STOP=1 "$@"; }
sql_replica() { dc exec -T replica psql -X -U postgres -d telemetry -v ON_ERROR_STOP=1 "$@"; }
action=${1:-help}
if [ "$#" -gt 0 ]; then shift; fi
case "$action" in
  up) dc up -d --wait primary ;;
  init-replica)
    dc up -d --wait primary
    dc run --rm --no-deps --entrypoint sh replica /lab/bootstrap-replica.sh
    dc up -d --wait --no-deps replica
    ;;
  start-replica) dc up -d --wait --no-deps replica ;;
  stop-replica) dc stop -t 10 replica ;;
  sql-primary) sql_primary "$@" ;;
  sql-replica) sql_replica "$@" ;;
  seed)
    rows=${1:-100000}
    case "$rows" in ''|*[!0-9]*) echo 'Размер порции должен быть целым числом.' >&2; exit 2;; esac
    if [ "${#rows}" -gt 7 ] || [ "$rows" -lt 1000 ] || [ "$rows" -gt 1000000 ]; then
      echo 'Допустимый размер порции: 1000..1000000.' >&2; exit 2
    fi
    sql_primary -v rows="$rows" < "$LAB_DIR/seed.sql"
    ;;
  inspect) sql_primary < "$LAB_DIR/inspect.sql" ;;
  status)
    sql_primary < "$LAB_DIR/status-primary.sql"
    sql_replica < "$LAB_DIR/status-replica.sql"
    ;;
  pause)
    sql_replica -c 'SELECT pg_wal_replay_pause();'
    attempts=0
    while [ "$(sql_replica -Atc 'SELECT pg_get_wal_replay_pause_state();')" != paused ]; do
      attempts=$((attempts + 1))
      if [ "$attempts" -ge 30 ]; then echo 'Не удалось дождаться паузы применения WAL.' >&2; exit 1; fi
      sleep 1
    done
    echo 'Применение WAL: paused'
    ;;
  resume) sql_replica -c 'SELECT pg_wal_replay_resume();' ;;
  logs) dc logs --tail 80 "$@" ;;
  down) dc --profile replica down ;;
  reset) dc --profile replica down --volumes --remove-orphans ;;
  help)
    echo 'sh lab.sh up | init-replica | start-replica | stop-replica'
    echo 'sh lab.sh sql-primary [параметры psql] | sql-replica [параметры psql]'
    echo 'sh lab.sh seed [1000..1000000] | inspect | status | pause | resume'
    echo 'sh lab.sh logs [primary|replica] | down | reset'
    ;;
  *) echo "Неизвестная команда: $action" >&2; exit 2 ;;
esac

#!/bin/sh
set -eu
BASE=/tmp/course07
TARGET=${1:?Restore point name required}
if [ -f "$BASE/restored/postmaster.pid" ]; then
  pg_ctl -D "$BASE/restored" -m fast -w stop
fi
rm -rf "$BASE/restored"
cp -a "$BASE/basebackup" "$BASE/restored"
touch "$BASE/restored/recovery.signal"
cat >> "$BASE/restored/postgresql.auto.conf" <<CONF
port=5542
archive_mode=off
restore_command='cp /tmp/course07/archive/%f %p'
recovery_target_name='$TARGET'
recovery_target_action='pause'
hot_standby=on
CONF
pg_ctl -D "$BASE/restored" -l "$BASE/restored.log" -w start

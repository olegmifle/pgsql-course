\pset pager off
SELECT pg_is_in_recovery() AS in_recovery;
SHOW synchronous_commit;
SHOW synchronous_standby_names;
SELECT application_name, state, sync_state,
       sent_lsn, write_lsn, flush_lsn, replay_lsn,
       pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS not_replayed_bytes
FROM pg_stat_replication;

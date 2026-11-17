\pset pager off
SELECT pg_is_in_recovery() AS in_recovery,
       pg_get_wal_replay_pause_state() AS replay_pause_state,
       pg_last_wal_receive_lsn() AS received_lsn,
       pg_last_wal_replay_lsn() AS replayed_lsn,
       pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn()) AS waiting_replay_bytes;

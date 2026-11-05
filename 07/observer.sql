\pset pager off
SELECT application_name,state,sync_state,write_lsn,flush_lsn,replay_lsn
FROM pg_stat_replication ORDER BY application_name;
SELECT application_name,state,wait_event_type,wait_event,query
FROM pg_stat_activity
WHERE datname=current_database() AND pid<>pg_backend_pid() AND backend_type='client backend'
ORDER BY application_name;

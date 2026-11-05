SELECT pg_stat_clear_snapshot();
SELECT pid,application_name,state,wait_event_type,wait_event,pg_blocking_pids(pid) AS blockers
FROM pg_stat_activity WHERE datname=current_database() AND application_name='live06-B';

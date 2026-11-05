\pset pager off
SELECT pid,application_name,state,wait_event_type,wait_event,
       pg_blocking_pids(pid) AS blockers,xact_start,left(query,160) AS query
FROM pg_stat_activity
WHERE datname=current_database() AND pid<>pg_backend_pid()
ORDER BY application_name,pid;
SELECT a.application_name,l.locktype,l.mode,l.granted,l.relation::regclass
FROM pg_locks l JOIN pg_stat_activity a ON a.pid=l.pid
WHERE a.datname=current_database()
ORDER BY a.application_name,l.granted,l.locktype;

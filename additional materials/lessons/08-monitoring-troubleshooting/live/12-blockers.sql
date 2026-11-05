SELECT w.pid AS waiting_pid,w.application_name AS waiting_app,
       w.state,w.wait_event_type,w.wait_event,
       b.pid AS blocker_pid,b.application_name AS blocker_app,b.state AS blocker_state,
       clock_timestamp()-b.xact_start AS blocker_xact_age,
       left(b.query,90) AS blocker_last_query
FROM pg_stat_activity w
CROSS JOIN LATERAL unnest(pg_blocking_pids(w.pid)) AS edge(pid)
LEFT JOIN pg_stat_activity b ON b.pid=edge.pid
WHERE w.datname=current_database();

SELECT w.pid AS waiter,w.application_name AS waiting_app,w.state AS waiting_state,
       w.wait_event_type,w.wait_event,w.backend_start AS waiting_backend_start,
       edge.pid AS blocker,b.application_name AS blocking_app,b.state AS blocking_state,
       b.backend_start AS blocking_backend_start,
       clock_timestamp()-b.xact_start AS blocking_xact_age,left(b.query,100) AS blocking_last_query
FROM pg_stat_activity w
CROSS JOIN LATERAL unnest(pg_blocking_pids(w.pid)) edge(pid)
LEFT JOIN pg_stat_activity b ON b.pid=edge.pid
WHERE w.datname=current_database();

-- pg_blocking_pids also includes soft blockers earlier in a lock queue.
SELECT w.pid AS waiter,w.application_name AS waiting_app,
       w.wait_event_type,w.wait_event,edge.pid AS blocker,
       b.application_name AS blocking_app,b.state AS blocking_state,
       clock_timestamp()-b.xact_start AS blocking_xact_age,
       left(b.query,120) AS blocking_current_or_last_query
FROM pg_stat_activity w
CROSS JOIN LATERAL unnest(pg_blocking_pids(w.pid)) edge(pid)
LEFT JOIN pg_stat_activity b ON b.pid=edge.pid
WHERE w.datname=current_database();
-- If blocker=0: inspect pg_prepared_xacts with the operator; no normal PID exists.

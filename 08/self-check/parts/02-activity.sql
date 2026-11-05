SELECT pid,usename,application_name,state,
       clock_timestamp()-xact_start AS xact_age,
       CASE WHEN state='active' THEN clock_timestamp()-query_start END AS active_query_age,
       clock_timestamp()-state_change AS state_age,
       wait_event_type,wait_event,backend_xmin,
       left(query,160) AS current_or_last_query
FROM pg_stat_activity
WHERE datname=current_database() AND pid<>pg_backend_pid()
ORDER BY xact_start NULLS LAST;

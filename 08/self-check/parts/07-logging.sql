SELECT name,setting,unit,context,pending_restart
FROM pg_settings WHERE name IN (
 'shared_preload_libraries','compute_query_id','track_io_timing',
 'log_min_duration_statement','log_lock_waits','deadlock_timeout',
 'log_line_prefix','log_min_error_statement',
 'log_autovacuum_min_duration','idle_in_transaction_session_timeout')
ORDER BY name;

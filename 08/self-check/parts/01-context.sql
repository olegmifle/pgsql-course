SELECT clock_timestamp() AS observed_at,current_database(),current_user,
       version(),pg_postmaster_start_time(),pg_is_in_recovery();
SELECT stats_reset,deadlocks,temp_bytes,blks_read,blks_hit
FROM pg_stat_database WHERE datname=current_database();
SELECT stats_reset,dealloc FROM pg_stat_statements_info;
SELECT count(*) FILTER (WHERE backend_type='client backend') AS cluster_clients,
       count(*) FILTER (WHERE backend_type='client backend' AND datname=current_database()) AS this_db_clients,
       current_setting('max_connections') AS max_connections,
       current_setting('reserved_connections') AS reserved_connections,
       current_setting('superuser_reserved_connections') AS superuser_reserved_connections
FROM pg_stat_activity;

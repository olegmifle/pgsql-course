SELECT application_name,state,backend_xmin,age(backend_xmin) AS xmin_age,
       clock_timestamp()-xact_start AS xact_age
FROM pg_stat_activity
WHERE datname=current_database() AND backend_xmin IS NOT NULL
ORDER BY age(backend_xmin) DESC;
SELECT relname,n_live_tup,n_dead_tup,last_vacuum,last_autovacuum,
       pg_relation_size(relid) AS heap_bytes
FROM pg_stat_user_tables WHERE schemaname='incident08' AND relname='events';

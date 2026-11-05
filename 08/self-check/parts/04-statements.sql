SELECT userid,dbid,queryid,toplevel,stats_since,calls,
       round(total_exec_time::numeric,1) AS total_ms,
       round(mean_exec_time::numeric,3) AS mean_ms,
       shared_blks_hit,shared_blks_read,temp_blks_written,
       left(query,160) AS query
FROM pg_stat_statements
WHERE dbid=(SELECT oid FROM pg_database WHERE datname=current_database())
ORDER BY total_exec_time DESC LIMIT 10;

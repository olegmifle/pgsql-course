DROP TABLE IF EXISTS window_start;
CREATE TEMP TABLE window_start AS
SELECT dbid,userid,queryid,toplevel,query,calls,total_exec_time,rows,
       shared_blks_hit,shared_blks_read,stats_since
FROM pg_stat_statements WHERE dbid=(SELECT oid FROM pg_database WHERE datname=current_database());
SELECT clock_timestamp() AS captured_at, stats_reset,dealloc FROM pg_stat_statements_info;

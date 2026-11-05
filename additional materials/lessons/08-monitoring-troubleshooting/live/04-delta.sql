-- Compare the same entries only; reset/recreated entries are rejected.
WITH pairs AS (
 SELECT e.queryid,e.query,e.calls-s.calls AS calls,
        e.total_exec_time-s.total_exec_time AS exec_ms,
        e.shared_blks_hit-s.shared_blks_hit AS hits,
        e.shared_blks_read-s.shared_blks_read AS reads,
        CASE WHEN s.queryid IS NULL THEN 'new entry'
             WHEN e.stats_since<>s.stats_since OR e.calls<s.calls
               OR e.total_exec_time<s.total_exec_time THEN 'reset/recreated'
             ELSE 'comparable' END AS quality
 FROM window_end e LEFT JOIN window_start s USING(dbid,userid,queryid,toplevel)
)
SELECT queryid,quality,calls,
       round(exec_ms::numeric,2) AS total_ms,
       round((exec_ms/nullif(calls,0))::numeric,3) AS mean_ms,hits,reads,
       left(query,100) AS query
FROM pairs WHERE quality='comparable' AND calls>0
ORDER BY exec_ms DESC LIMIT 8;
-- New/recreated entries are visible separately, never silently counted as zero.
SELECT e.queryid,left(e.query,80) AS excluded_query
FROM window_end e LEFT JOIN window_start s USING(dbid,userid,queryid,toplevel)
WHERE s.queryid IS NULL OR e.stats_since<>s.stats_since OR e.calls<s.calls;
SELECT s.queryid,left(s.query,80) AS disappeared_query
FROM window_start s LEFT JOIN window_end e USING(dbid,userid,queryid,toplevel)
WHERE e.queryid IS NULL;

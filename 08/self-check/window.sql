WITH compared AS (
 SELECT coalesce(e.dbid,s.dbid) AS dbid,
        coalesce(e.userid,s.userid) AS userid,
        coalesce(e.queryid,s.queryid) AS queryid,
        coalesce(e.toplevel,s.toplevel) AS toplevel,
        coalesce(e.query,s.query) AS query,
        CASE WHEN e.queryid IS NULL THEN 'disappeared'
             WHEN s.queryid IS NULL THEN 'new entry'
             WHEN e.stats_since IS DISTINCT FROM s.stats_since
               OR e.calls<s.calls OR e.total_exec_time<s.total_exec_time
               OR e.shared_blks_hit<s.shared_blks_hit OR e.shared_blks_read<s.shared_blks_read
               THEN 'reset/recreated'
             ELSE 'comparable' END AS quality,
        e.calls-s.calls AS dcalls,e.total_exec_time-s.total_exec_time AS dtime,
        e.shared_blks_hit-s.shared_blks_hit AS dhit,e.shared_blks_read-s.shared_blks_read AS dread
 FROM hw08_window_end e FULL JOIN hw08_window_start s USING(dbid,userid,queryid,toplevel)
)
SELECT queryid,quality,
       CASE WHEN quality='comparable' THEN dcalls END AS calls,
       CASE WHEN quality='comparable' THEN round(dtime::numeric,3) END AS total_ms,
       CASE WHEN quality='comparable' THEN round((dtime/nullif(dcalls,0))::numeric,3) END AS mean_ms,
       CASE WHEN quality='comparable' THEN dhit END AS hits,
       CASE WHEN quality='comparable' THEN dread END AS reads,
       left(query,120) AS query
FROM compared
WHERE quality<>'comparable' OR dcalls>0
ORDER BY quality,total_ms DESC NULLS LAST,queryid;

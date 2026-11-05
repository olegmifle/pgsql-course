SELECT relid::regclass AS relation,n_live_tup,n_dead_tup,n_mod_since_analyze,
       last_vacuum,last_autovacuum,last_analyze,last_autoanalyze,
       pg_relation_size(relid) AS heap_bytes,pg_total_relation_size(relid) AS total_bytes,
       age(c.relfrozenxid) AS xid_age,c.reloptions
FROM pg_stat_user_tables s JOIN pg_class c ON c.oid=s.relid
ORDER BY n_dead_tup DESC;

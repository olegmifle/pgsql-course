\pset pager off
SELECT version();
SHOW block_size;
SELECT count(*) AS rows,
       round(avg(pg_column_size(r)), 2) AS mean_tuple_bytes
FROM public.readings AS r;
WITH RECURSIVE relations(relid) AS (
  SELECT 'public.readings'::regclass::oid
  UNION ALL
  SELECT i.inhrelid FROM pg_inherits i
  JOIN relations r ON i.inhparent = r.relid
)
SELECT sum(pg_relation_size(relid)) AS heap_bytes,
       sum(pg_table_size(relid)) AS table_bytes,
       sum(pg_indexes_size(relid)) AS indexes_bytes,
       sum(pg_total_relation_size(relid)) AS total_bytes
FROM relations
WHERE NOT EXISTS (SELECT 1 FROM pg_inherits WHERE inhparent = relid);
WITH RECURSIVE relations(relid) AS (
  SELECT 'public.readings'::regclass::oid
  UNION ALL
  SELECT i.inhrelid FROM pg_inherits i
  JOIN relations r ON i.inhparent = r.relid
)
SELECT r.relid::regclass AS table_name,
       pg_get_indexdef(i.indexrelid) AS index_definition
FROM relations r JOIN pg_index i ON i.indrelid = r.relid;

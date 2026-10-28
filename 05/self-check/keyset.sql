\set ON_ERROR_STOP on
SET TIME ZONE 'UTC';
SELECT created_at AS last_time,id AS last_id FROM hw05.orders
WHERE store_id=1 AND created_at>=timestamptz '2026-01-02 00:00:00+00'
ORDER BY created_at DESC,id DESC LIMIT 1 OFFSET 4999
\gset cursor_
EXPLAIN (ANALYZE,BUFFERS)
SELECT id,created_at,status,total_amount FROM hw05.orders
WHERE store_id=1 AND created_at>=timestamptz '2026-01-02 00:00:00+00'
AND (created_at,id)<(:'cursor_last_time'::timestamptz,:'cursor_last_id'::bigint)
ORDER BY created_at DESC,id DESC LIMIT 20;

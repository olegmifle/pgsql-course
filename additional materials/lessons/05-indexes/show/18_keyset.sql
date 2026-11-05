EXPLAIN (ANALYZE, BUFFERS)
SELECT id, created_at, status, price FROM orders
WHERE store_id = 1
  AND created_at >= timestamptz '2026-01-03 00:00:00+00'
  AND (created_at, id) < (:'last_time'::timestamptz, :'last_id'::bigint)
ORDER BY created_at DESC, id DESC
LIMIT 20;

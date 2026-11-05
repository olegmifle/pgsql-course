EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM orders
WHERE store_id = 1 AND status = 'pending'
  AND created_at >= timestamptz '2026-01-03 00:00:00+00';

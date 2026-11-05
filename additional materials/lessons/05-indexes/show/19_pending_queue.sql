EXPLAIN (ANALYZE, BUFFERS)
SELECT id, created_at FROM orders
WHERE store_id = 42 AND status = 'pending'
ORDER BY created_at, id
LIMIT 20;

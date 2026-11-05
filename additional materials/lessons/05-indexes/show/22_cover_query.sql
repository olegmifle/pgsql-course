EXPLAIN (ANALYZE, BUFFERS)
SELECT id, created_at, status, price FROM orders
WHERE store_id = 42
ORDER BY created_at DESC, id DESC
LIMIT 20;

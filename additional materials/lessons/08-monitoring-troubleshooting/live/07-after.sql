EXPLAIN (ANALYZE, BUFFERS)
SELECT id, total_cents FROM incident08.orders
WHERE tenant_id=7 AND status='pending'
ORDER BY created_at DESC, id DESC LIMIT 20;

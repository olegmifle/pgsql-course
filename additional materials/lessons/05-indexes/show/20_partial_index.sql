CREATE INDEX orders_pending_idx
ON orders(store_id, created_at, id)
WHERE status = 'pending';

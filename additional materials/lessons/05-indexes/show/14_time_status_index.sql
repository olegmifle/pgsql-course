CREATE INDEX orders_range_status_idx
ON orders(store_id, created_at DESC, status, id DESC);

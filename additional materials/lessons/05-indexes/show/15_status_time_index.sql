DROP INDEX live5.orders_range_status_idx;
CREATE INDEX orders_status_range_idx
ON orders(store_id, status, created_at DESC, id DESC);

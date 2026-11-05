CREATE INDEX CONCURRENTLY orders_qr_trgm_idx
ON orders USING gin(qr gin_trgm_ops);

CREATE INDEX CONCURRENTLY orders_qr_like_idx
ON orders(qr text_pattern_ops);

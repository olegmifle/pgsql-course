EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE qr LIKE :'qr_prefix' || '%';

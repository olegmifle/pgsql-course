EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE qr ILIKE '%' || :'qr_fragment' || '%';

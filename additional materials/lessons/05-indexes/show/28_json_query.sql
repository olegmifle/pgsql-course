EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM orders WHERE metadata @> '{"segment":"vip"}'::jsonb;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, email FROM customers WHERE lower(email) = 'user4242@example.test';

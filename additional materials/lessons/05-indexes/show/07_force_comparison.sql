BEGIN;
SET LOCAL enable_seqscan = off;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE qr < '2b3561d0c25d3e8bdaca5bc338057861';
ROLLBACK;
SHOW enable_seqscan;

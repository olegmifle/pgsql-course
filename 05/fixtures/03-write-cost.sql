\set ON_ERROR_STOP on
SET TIME ZONE 'UTC';
-- Один опыт на набор индексов, после остальных замеров чтения.
-- EXPLAIN ANALYZE выполняет запись. После ROLLBACK значения восстанавливаются; работа со страницами и WAL остаётся.
BEGIN;
EXPLAIN (ANALYZE,BUFFERS,WAL)
INSERT INTO hw05.orders
SELECT i,2+(i%99)::int,timestamptz '2026-01-01 00:00:00+00'+i*interval '1 second',
 CASE WHEN i%97=0 THEN 'pending' ELSE 'paid' END,((i%100000)/100.0)::numeric(12,2),
 jsonb_build_object('segment','regular','channel','web'),repeat(md5(i::text),4)
FROM generate_series(300001,302500) g(i);
EXPLAIN (ANALYZE,BUFFERS,WAL)
UPDATE hw05.orders SET total_amount=total_amount+0.01
WHERE id IN(SELECT id FROM hw05.orders WHERE store_id=1 AND status='pending'
 ORDER BY created_at DESC,id DESC LIMIT 500);
ROLLBACK;

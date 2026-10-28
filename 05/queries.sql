\set ON_ERROR_STOP on
SET TIME ZONE 'UTC';
\pset pager off
-- Для замеров выполняйте отдельный блок: прогрев и три одинаковых запуска.
-- Файлы индексов применяются отдельно; SELECT можно переписать с сохранением результата и порядка.

-- QF1
EXPLAIN (ANALYZE,BUFFERS)
SELECT id,created_at,status,total_amount FROM hw05.orders WHERE store_id=1 AND created_at>=timestamptz '2026-01-02 00:00:00+00' ORDER BY created_at DESC,id DESC LIMIT 20;

-- QF42
EXPLAIN (ANALYZE,BUFFERS)
SELECT id,created_at,status,total_amount FROM hw05.orders WHERE store_id=42 AND created_at>=timestamptz '2026-01-02 00:00:00+00' ORDER BY created_at DESC,id DESC LIMIT 20;

-- QW1
EXPLAIN (ANALYZE,BUFFERS)
SELECT id,created_at FROM hw05.orders WHERE store_id=1 AND status='pending' ORDER BY created_at,id LIMIT 20;

-- QW42
EXPLAIN (ANALYZE,BUFFERS)
SELECT id,created_at FROM hw05.orders WHERE store_id=42 AND status='pending' ORDER BY created_at,id LIMIT 20;

-- QE
EXPLAIN (ANALYZE,BUFFERS)
SELECT id,email FROM hw05.customers WHERE lower(email)='user4242@example.test';

-- QJ
EXPLAIN (ANALYZE,BUFFERS)
SELECT id FROM hw05.orders WHERE metadata @> '{"segment":"vip"}'::jsonb;

-- QC
EXPLAIN (ANALYZE,BUFFERS)
SELECT id FROM hw05.orders WHERE metadata ? 'coupon';

-- QT
EXPLAIN (ANALYZE,BUFFERS)
SELECT count(*) FROM hw05.events WHERE occurred_at>=timestamptz '2026-01-03 00:00:00+00' AND occurred_at<timestamptz '2026-01-03 01:00:00+00';

-- QPAGE
EXPLAIN (ANALYZE,BUFFERS)
SELECT id,created_at,status,total_amount FROM hw05.orders WHERE store_id=1 AND created_at>=timestamptz '2026-01-02 00:00:00+00' ORDER BY created_at DESC,id DESC LIMIT 20 OFFSET 5000;

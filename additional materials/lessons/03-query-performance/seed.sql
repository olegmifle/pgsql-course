\set ON_ERROR_STOP on
BEGIN;
INSERT INTO lab.customers
SELECT g, 'customer_' || g,
       CASE WHEN g = 1200 THEN NULL
            WHEN g <= 600 THEN 'EU' ELSE 'OTHER' END
FROM generate_series(1, 1200) AS s(g);

INSERT INTO lab.orders
SELECT g, 1 + (g - 1) % 1188,
       CASE WHEN (1 + (g - 1) % 1188) % 37 = 0 THEN 'pending'
            WHEN g % 10 < 7 THEN 'paid' ELSE 'pending' END,
       timestamp '2026-01-01' + ((g / 10) % 120) * interval '1 day',
       10000 + (g % 10) * 100
FROM generate_series(1, 48000) AS s(g);

-- Отсутствующие позиции у части заказов, повторяющиеся цены.
INSERT INTO lab.order_items
SELECT (o.id - 1) * 3 + s.slot, o.id,
       1 + (o.id + s.slot * 17) % 100, s.slot, 1000
FROM lab.orders o CROSS JOIN generate_series(1, 3) AS s(slot)
WHERE o.id % 97 <> 0;

-- Возможны ноль, одна и две успешные попытки оплаты.
INSERT INTO lab.payments
SELECT (o.id - 1) * 2 + s.slot, o.id,
       CASE WHEN s.slot = 1 AND o.id % 5 <> 0 THEN 'success'
            WHEN s.slot = 2 AND o.id % 7 = 0 THEN 'success'
            ELSE 'failed' END, o.total_cents
FROM lab.orders o CROSS JOIN generate_series(1, 2) AS s(slot);
-- Запись без привязки к заказу: контрпример для NOT IN.
INSERT INTO lab.payments VALUES (96001, NULL, 'success', 100);

INSERT INTO lab.events
SELECT (o.id - 1) * 8 + s.slot, o.id,
       CASE WHEN s.slot % 4 = 0 THEN 'email' ELSE 'view' END,
       o.created_at + ((s.slot - 1) / 2) * interval '1 minute',
       repeat(md5(o.id::text || ':' || s.slot::text), 8)
FROM lab.orders o CROSS JOIN generate_series(1, 8) AS s(slot)
WHERE o.id % 113 <> 0;
COMMIT;
VACUUM (ANALYZE) lab.customers;
VACUUM (ANALYZE) lab.orders;
VACUUM (ANALYZE) lab.order_items;
VACUUM (ANALYZE) lab.payments;
VACUUM (ANALYZE) lab.events;

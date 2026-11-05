\set ON_ERROR_STOP on
-- Не оптимизации: короткие контрпримеры для разбора смысла SQL.
BEGIN READ ONLY;
-- NULL в подзапросе NOT IN: первая выдача не эквивалентна второй.
SELECT count(*) AS naive_not_in
FROM lab.orders o
WHERE o.id NOT IN (SELECT p.order_id FROM lab.payments p WHERE p.status = 'success');
SELECT count(*) AS correct_not_exists
FROM lab.orders o
WHERE NOT EXISTS (SELECT FROM lab.payments p WHERE p.order_id = o.id AND p.status = 'success');

-- Заказ 97 не имеет позиций: COUNT(*) = 1, COUNT(i.id) = 0.
SELECT o.id, count(*) AS joined_rows, count(i.id) AS real_items,
       sum(i.qty * i.price_cents) AS sum_without_coalesce
FROM lab.orders o LEFT JOIN lab.order_items i ON i.order_id = o.id
WHERE o.id = 97 GROUP BY o.id;

-- Заказ 7 имеет две успешные оплаты, три позиции.
SELECT o.id, count(*) AS combinations,
       sum(i.qty * i.price_cents) AS duplicated_item_total
FROM lab.orders o
JOIN lab.order_items i ON i.order_id = o.id
JOIN lab.payments p ON p.order_id = o.id AND p.status = 'success'
WHERE o.id = 7 GROUP BY o.id;
SELECT order_id, sum(qty * price_cents) AS correct_item_total
FROM lab.order_items WHERE order_id = 7 GROUP BY order_id;

-- Два события с максимальным временем у заказа 7: нужны оба ключа ORDER BY.
SELECT id, event_type, occurred_at FROM lab.events
WHERE order_id = 7 ORDER BY occurred_at DESC, id DESC LIMIT 2;

-- Обычный EXCEPT не различает кратности, EXCEPT ALL различает.
SELECT count(*) AS ordinary_except_difference
FROM ((VALUES (1), (1)) EXCEPT (VALUES (1))) d;
SELECT count(*) AS except_all_difference
FROM ((VALUES (1), (1)) EXCEPT ALL (VALUES (1))) d;
ROLLBACK;

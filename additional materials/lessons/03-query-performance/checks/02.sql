\set ON_ERROR_STOP on
\ir ../settings.sql
-- Оба результата вычисляются в одном снимке. EXCEPT ALL учитывает дубли.
WITH before_result AS MATERIALIZED (
-- Q2: уникальные оплаченные заказы, у которых есть позиция sku <= 50,
-- успешная оплата и событие email. Число дочерних строк неважно.
SELECT DISTINCT o.id AS order_id, o.customer_id
FROM lab.orders o
JOIN lab.order_items i ON i.order_id = o.id AND i.sku_id <= 50
JOIN lab.payments p ON p.order_id = o.id AND p.status = 'success'
JOIN lab.events e ON e.order_id = o.id AND e.event_type = 'email'
WHERE o.status = 'paid'
), after_result AS MATERIALIZED (
SELECT o.id AS order_id, o.customer_id
FROM lab.orders o
WHERE o.status = 'paid'
  AND EXISTS (SELECT FROM lab.order_items i
              WHERE i.order_id = o.id AND i.sku_id <= 50)
  AND EXISTS (SELECT FROM lab.payments p
              WHERE p.order_id = o.id AND p.status = 'success')
  AND EXISTS (SELECT FROM lab.events e
              WHERE e.order_id = o.id AND e.event_type = 'email')
)
SELECT
 (SELECT count(*) FROM before_result) AS before_rows,
 (SELECT count(*) FROM after_result) AS after_rows,
 (SELECT count(*) FROM (TABLE before_result EXCEPT ALL TABLE after_result) d) AS before_minus_after,
 (SELECT count(*) FROM (TABLE after_result EXCEPT ALL TABLE before_result) d) AS after_minus_before;

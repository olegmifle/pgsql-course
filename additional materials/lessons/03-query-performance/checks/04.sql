\set ON_ERROR_STOP on
\ir ../settings.sql
-- Оба результата вычисляются в одном снимке. EXCEPT ALL учитывает дубли.
WITH before_result AS MATERIALIZED (
-- Q4: оплаченные заказы за два дня и стоимость/число их позиций.
-- Заказ без позиций остаётся с нулями. total_cents не заменяет item_total.
SELECT o.id AS order_id, o.customer_id,
       COALESCE(m.item_total, 0) AS item_total,
       COALESCE(m.item_count, 0) AS item_count
FROM lab.orders o
LEFT JOIN (
  SELECT order_id, sum(qty * price_cents) AS item_total,
         count(*) AS item_count
  FROM lab.order_items
  GROUP BY order_id
) m ON m.order_id = o.id
WHERE o.status = 'paid'
  AND o.created_at >= timestamp '2026-04-29'
  AND o.created_at < timestamp '2026-05-01'
), after_result AS MATERIALIZED (
SELECT o.id AS order_id, o.customer_id,
       COALESCE(sum(i.qty * i.price_cents), 0) AS item_total,
       count(i.id) AS item_count
FROM lab.orders o
LEFT JOIN lab.order_items i ON i.order_id = o.id
WHERE o.status = 'paid'
  AND o.created_at >= timestamp '2026-04-29'
  AND o.created_at < timestamp '2026-05-01'
GROUP BY o.id, o.customer_id
)
SELECT
 (SELECT count(*) FROM before_result) AS before_rows,
 (SELECT count(*) FROM after_result) AS after_rows,
 (SELECT count(*) FROM (TABLE before_result EXCEPT ALL TABLE after_result) d) AS before_minus_after,
 (SELECT count(*) FROM (TABLE after_result EXCEPT ALL TABLE before_result) d) AS after_minus_before;

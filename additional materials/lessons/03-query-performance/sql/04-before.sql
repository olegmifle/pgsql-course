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
  AND o.created_at < timestamp '2026-05-01';

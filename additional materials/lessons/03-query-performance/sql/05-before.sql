-- Q5: последнее событие каждого оплаченного заказа за два дня.
-- Порядок внутри заказа: occurred_at DESC, id DESC; без событий заказ не входит.
SELECT o.id AS order_id, e.id AS event_id, e.event_type, e.occurred_at
FROM lab.orders o
JOIN (
  SELECT id, order_id, event_type, occurred_at,
         row_number() OVER (
           PARTITION BY order_id ORDER BY occurred_at DESC, id DESC
         ) AS rn
  FROM lab.events
) e ON e.order_id = o.id AND e.rn = 1
WHERE o.status = 'paid'
  AND o.created_at >= timestamp '2026-04-29'
  AND o.created_at < timestamp '2026-05-01';

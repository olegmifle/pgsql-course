SELECT o.id AS order_id, o.customer_id,
       COALESCE(sum(i.qty * i.price_cents), 0) AS item_total,
       count(i.id) AS item_count
FROM lab.orders o
LEFT JOIN lab.order_items i ON i.order_id = o.id
WHERE o.status = 'paid'
  AND o.created_at >= timestamp '2026-04-29'
  AND o.created_at < timestamp '2026-05-01'
GROUP BY o.id, o.customer_id;

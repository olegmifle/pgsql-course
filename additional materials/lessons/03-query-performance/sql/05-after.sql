SELECT DISTINCT ON (o.id)
       o.id AS order_id, e.id AS event_id, e.event_type, e.occurred_at
FROM lab.orders o
JOIN lab.events e ON e.order_id = o.id
WHERE o.status = 'paid'
  AND o.created_at >= timestamp '2026-04-29'
  AND o.created_at < timestamp '2026-05-01'
ORDER BY o.id, e.occurred_at DESC, e.id DESC;

SELECT id AS event_id, order_id, occurred_at
FROM lab.events
WHERE event_type = 'email'
  AND occurred_at >= timestamp '2026-04-29'
  AND occurred_at < timestamp '2026-05-01';

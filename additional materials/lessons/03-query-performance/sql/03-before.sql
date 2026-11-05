-- Q3: события email за полуоткрытый интервал; payload не нужен.
WITH all_events AS MATERIALIZED (
  SELECT * FROM lab.events
)
SELECT id AS event_id, order_id, occurred_at
FROM all_events
WHERE event_type = 'email'
  AND occurred_at >= timestamp '2026-04-29'
  AND occurred_at < timestamp '2026-05-01';

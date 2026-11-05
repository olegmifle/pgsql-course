\set ON_ERROR_STOP on
\ir ../settings.sql
-- Оба результата вычисляются в одном снимке. EXCEPT ALL учитывает дубли.
WITH before_result AS MATERIALIZED (
-- Q3: события email за полуоткрытый интервал; payload не нужен.
WITH all_events AS MATERIALIZED (
  SELECT * FROM lab.events
)
SELECT id AS event_id, order_id, occurred_at
FROM all_events
WHERE event_type = 'email'
  AND occurred_at >= timestamp '2026-04-29'
  AND occurred_at < timestamp '2026-05-01'
), after_result AS MATERIALIZED (
SELECT id AS event_id, order_id, occurred_at
FROM lab.events
WHERE event_type = 'email'
  AND occurred_at >= timestamp '2026-04-29'
  AND occurred_at < timestamp '2026-05-01'
)
SELECT
 (SELECT count(*) FROM before_result) AS before_rows,
 (SELECT count(*) FROM after_result) AS after_rows,
 (SELECT count(*) FROM (TABLE before_result EXCEPT ALL TABLE after_result) d) AS before_minus_after,
 (SELECT count(*) FROM (TABLE after_result EXCEPT ALL TABLE before_result) d) AS after_minus_before;

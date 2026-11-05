\set ON_ERROR_STOP on
\ir ../settings.sql
-- Оба результата вычисляются в одном снимке. EXCEPT ALL учитывает дубли.
WITH before_result AS MATERIALIZED (
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
  AND o.created_at < timestamp '2026-05-01'
), after_result AS MATERIALIZED (
SELECT DISTINCT ON (o.id)
       o.id AS order_id, e.id AS event_id, e.event_type, e.occurred_at
FROM lab.orders o
JOIN lab.events e ON e.order_id = o.id
WHERE o.status = 'paid'
  AND o.created_at >= timestamp '2026-04-29'
  AND o.created_at < timestamp '2026-05-01'
ORDER BY o.id, e.occurred_at DESC, e.id DESC
)
SELECT
 (SELECT count(*) FROM before_result) AS before_rows,
 (SELECT count(*) FROM after_result) AS after_rows,
 (SELECT count(*) FROM (TABLE before_result EXCEPT ALL TABLE after_result) d) AS before_minus_after,
 (SELECT count(*) FROM (TABLE after_result EXCEPT ALL TABLE before_result) d) AS after_minus_before;

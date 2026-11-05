\set ON_ERROR_STOP on
\ir ../settings.sql
-- Оба результата вычисляются в одном снимке. EXCEPT ALL учитывает дубли.
WITH before_result AS MATERIALIZED (
-- Q1: все клиенты, число оплаченных заказов и сумма их total_cents.
-- Клиенты без оплаченных заказов остаются с двумя нулями.
SELECT c.id AS customer_id,
       (SELECT count(*) FROM lab.orders o
        WHERE o.customer_id = c.id AND o.status = 'paid') AS paid_count,
       COALESCE((SELECT sum(o.total_cents) FROM lab.orders o
                 WHERE o.customer_id = c.id AND o.status = 'paid'), 0) AS paid_total
FROM lab.customers c
), after_result AS MATERIALIZED (
SELECT c.id AS customer_id,
       COALESCE(m.paid_count, 0) AS paid_count,
       COALESCE(m.paid_total, 0) AS paid_total
FROM lab.customers c
LEFT JOIN (
  SELECT customer_id, count(*) AS paid_count,
         sum(total_cents) AS paid_total
  FROM lab.orders
  WHERE status = 'paid'
  GROUP BY customer_id
) m ON m.customer_id = c.id
)
SELECT
 (SELECT count(*) FROM before_result) AS before_rows,
 (SELECT count(*) FROM after_result) AS after_rows,
 (SELECT count(*) FROM (TABLE before_result EXCEPT ALL TABLE after_result) d) AS before_minus_after,
 (SELECT count(*) FROM (TABLE after_result EXCEPT ALL TABLE before_result) d) AS after_minus_before;

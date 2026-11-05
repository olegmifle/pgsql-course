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
) m ON m.customer_id = c.id;

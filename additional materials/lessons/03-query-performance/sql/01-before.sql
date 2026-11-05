-- Q1: все клиенты, число оплаченных заказов и сумма их total_cents.
-- Клиенты без оплаченных заказов остаются с двумя нулями.
SELECT c.id AS customer_id,
       (SELECT count(*) FROM lab.orders o
        WHERE o.customer_id = c.id AND o.status = 'paid') AS paid_count,
       COALESCE((SELECT sum(o.total_cents) FROM lab.orders o
                 WHERE o.customer_id = c.id AND o.status = 'paid'), 0) AS paid_total
FROM lab.customers c;

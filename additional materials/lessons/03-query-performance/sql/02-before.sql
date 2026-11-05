-- Q2: уникальные оплаченные заказы, у которых есть позиция sku <= 50,
-- успешная оплата и событие email. Число дочерних строк неважно.
SELECT DISTINCT o.id AS order_id, o.customer_id
FROM lab.orders o
JOIN lab.order_items i ON i.order_id = o.id AND i.sku_id <= 50
JOIN lab.payments p ON p.order_id = o.id AND p.status = 'success'
JOIN lab.events e ON e.order_id = o.id AND e.event_type = 'email'
WHERE o.status = 'paid';

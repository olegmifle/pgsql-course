SELECT o.id AS order_id, o.customer_id
FROM lab.orders o
WHERE o.status = 'paid'
  AND EXISTS (SELECT FROM lab.order_items i
              WHERE i.order_id = o.id AND i.sku_id <= 50)
  AND EXISTS (SELECT FROM lab.payments p
              WHERE p.order_id = o.id AND p.status = 'success')
  AND EXISTS (SELECT FROM lab.events e
              WHERE e.order_id = o.id AND e.event_type = 'email');

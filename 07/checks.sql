\set ON_ERROR_STOP on
SELECT id,tenant_id,status,total_amount FROM hw07.orders ORDER BY id;
SELECT o.id,coalesce(sum(i.qty*i.unit_price),0) AS items_total,o.total_amount
FROM hw07.orders o LEFT JOIN hw07.order_items i ON o.id=i.order_id
GROUP BY o.id,o.total_amount
HAVING coalesce(sum(i.qty*i.unit_price),0)<>o.total_amount;
SELECT i.* FROM hw07.order_items i LEFT JOIN hw07.orders o ON o.id=i.order_id WHERE o.id IS NULL;
-- Добавьте проверки именно своего сценария. Сам по себе вывод без ошибок не означает PASS.

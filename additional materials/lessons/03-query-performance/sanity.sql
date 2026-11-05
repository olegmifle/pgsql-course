\set ON_ERROR_STOP on
SELECT 'customers' AS relation, count(*) AS rows FROM lab.customers
UNION ALL SELECT 'orders', count(*) FROM lab.orders
UNION ALL SELECT 'order_items', count(*) FROM lab.order_items
UNION ALL SELECT 'payments', count(*) FROM lab.payments
UNION ALL SELECT 'events', count(*) FROM lab.events;
SELECT tablename, indexname FROM pg_indexes WHERE schemaname = 'lab';
SELECT count(*) AS customers_without_orders FROM lab.customers c
WHERE NOT EXISTS (SELECT FROM lab.orders o WHERE o.customer_id = c.id);
SELECT count(*) AS orders_without_items FROM lab.orders o
WHERE NOT EXISTS (SELECT FROM lab.order_items i WHERE i.order_id = o.id);
SELECT count(*) AS orders_without_events FROM lab.orders o
WHERE NOT EXISTS (SELECT FROM lab.events e WHERE e.order_id = o.id);
DO $$
BEGIN
  IF (SELECT count(*) FROM lab.customers) <> 1200
     OR (SELECT count(*) FROM lab.orders) <> 48000
     OR (SELECT count(*) FROM lab.order_items) <> 142518
     OR (SELECT count(*) FROM lab.payments) <> 96001
     OR (SELECT count(*) FROM lab.events) <> 380608 THEN
    RAISE EXCEPTION 'Неверное число исходных строк';
  END IF;
  IF EXISTS (SELECT FROM pg_indexes WHERE schemaname = 'lab') THEN
    RAISE EXCEPTION 'На стенде появились индексы';
  END IF;
  IF EXISTS (SELECT id FROM lab.orders GROUP BY id HAVING count(*) <> 1)
     OR EXISTS (SELECT id FROM lab.customers GROUP BY id HAVING count(*) <> 1)
     OR EXISTS (SELECT id FROM lab.order_items GROUP BY id HAVING count(*) <> 1)
     OR EXISTS (SELECT id FROM lab.events GROUP BY id HAVING count(*) <> 1)
     OR EXISTS (SELECT id FROM lab.payments GROUP BY id HAVING count(*) <> 1) THEN
    RAISE EXCEPTION 'Нарушена уникальность учебных id';
  END IF;
  IF EXISTS (SELECT FROM lab.orders o LEFT JOIN lab.customers c ON c.id = o.customer_id WHERE c.id IS NULL)
     OR EXISTS (SELECT FROM lab.order_items i LEFT JOIN lab.orders o ON o.id = i.order_id WHERE o.id IS NULL)
     OR EXISTS (SELECT FROM lab.events e LEFT JOIN lab.orders o ON o.id = e.order_id WHERE o.id IS NULL)
     OR EXISTS (SELECT FROM lab.payments p LEFT JOIN lab.orders o ON o.id = p.order_id WHERE p.order_id IS NOT NULL AND o.id IS NULL) THEN
    RAISE EXCEPTION 'Нарушена связь учебных данных';
  END IF;
END $$;

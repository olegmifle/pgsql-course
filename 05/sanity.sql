\set ON_ERROR_STOP on
SET TIME ZONE 'UTC';
SELECT version(),current_database(),current_user;
DO $$ BEGIN
 IF (SELECT count(*) FROM hw05.orders)<>300000 OR
    (SELECT count(*) FROM hw05.customers)<>100000 OR
    (SELECT count(*) FROM hw05.events)<>600000 THEN
  RAISE EXCEPTION 'Initial row counts differ; use a fresh database and apply schema/seed once';
 END IF;
 IF (SELECT count(*) FROM hw05.orders WHERE store_id=1)<>150000 THEN
  RAISE EXCEPTION 'Store 1 must have 150000 orders';
 END IF;
END $$;
SELECT 'orders' AS relation,count(*) FROM hw05.orders
UNION ALL SELECT 'customers',count(*) FROM hw05.customers
UNION ALL SELECT 'events',count(*) FROM hw05.events;
SELECT store_id,count(*) FROM hw05.orders WHERE store_id IN(1,42) GROUP BY store_id;
SELECT count(*) FILTER(WHERE metadata ? 'coupon') AS coupon_key,
       count(*) FILTER(WHERE metadata->'coupon'='null'::jsonb) AS coupon_json_null
FROM hw05.orders;
SELECT indexname,indexdef FROM pg_indexes WHERE schemaname='hw05' ORDER BY indexname;

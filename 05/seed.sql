\set ON_ERROR_STOP on
SET TIME ZONE 'UTC';
INSERT INTO hw05.orders
SELECT i,CASE WHEN i<=150000 THEN 1 ELSE 2+(i%99)::int END,
 timestamptz '2026-01-01 00:00:00+00'+(i-i%4)*interval '1 second',
 CASE WHEN i%97=0 THEN 'pending' ELSE 'paid' END,
 ((i%100000)/100.0)::numeric(12,2),
 jsonb_build_object('segment',CASE WHEN i%997=0 THEN 'vip' ELSE 'regular' END,
                    'channel',CASE WHEN i%3=0 THEN 'app' ELSE 'web' END)
 ||CASE WHEN i%31=0 THEN jsonb_build_object('coupon',CASE WHEN i%310=0 THEN NULL::text ELSE 'SALE10' END) ELSE '{}'::jsonb END,
 repeat(md5(i::text),4)
FROM generate_series(1,300000) g(i);
INSERT INTO hw05.customers
SELECT i,'User'||i||'@Example.test','Customer '||i FROM generate_series(1,100000) g(i);
INSERT INTO hw05.events
SELECT i,timestamptz '2026-01-01 00:00:00+00'+i*interval '1 second',repeat(md5(i::text),3)
FROM generate_series(1,600000) g(i) ORDER BY i;
VACUUM (ANALYZE) hw05.orders;
VACUUM (ANALYZE) hw05.customers;
VACUUM (ANALYZE) hw05.events;

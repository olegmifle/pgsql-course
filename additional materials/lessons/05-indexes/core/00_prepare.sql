\set ON_ERROR_STOP on
\ir ../_display.sql
SET TIME ZONE 'UTC';
-- Одна загрузка в новой схеме. При существующей live5 транзакция отменится.
BEGIN;
CREATE SCHEMA live5;
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pageinspect WITH SCHEMA public;
CREATE TABLE live5.orders (
 id bigserial PRIMARY KEY,
 price bigint NOT NULL,
 qr text NOT NULL,
 store_id integer NOT NULL,
 created_at timestamptz NOT NULL,
 status text NOT NULL CHECK(status IN ('pending','paid')),
 metadata jsonb NOT NULL,
 payload text NOT NULL
) WITH(fillfactor=80);
INSERT INTO live5.orders(id,price,qr,store_id,created_at,status,metadata,payload)
SELECT i,1+(i%9999),md5(i::text),
 CASE WHEN i<=500000 THEN 1 ELSE 2+(i%99)::int END,
 timestamptz '2026-01-01 00:00:00+00'+(i-i%4)*interval '1 second',
 CASE WHEN i%97=0 THEN 'pending' ELSE 'paid' END,
 jsonb_build_object('segment',CASE WHEN i%997=0 THEN 'vip' ELSE 'regular' END,
                    'channel',CASE WHEN i%3=0 THEN 'app' ELSE 'web' END),
 repeat(md5(i::text),3)
FROM generate_series(1,1000000) AS g(i);
SELECT setval(pg_get_serial_sequence('live5.orders','id'),max(id)) FROM live5.orders;
CREATE TABLE live5.customers(id bigint PRIMARY KEY,email text NOT NULL);
INSERT INTO live5.customers SELECT i,'User'||i||'@Example.test' FROM generate_series(1,100000) AS g(i);
CREATE TABLE live5.events(id bigint PRIMARY KEY,occurred_at timestamptz NOT NULL,payload text NOT NULL);
INSERT INTO live5.events
SELECT i,timestamptz '2026-01-01 00:00:00+00'+i*interval '1 second',repeat(md5(i::text),3)
FROM generate_series(1,600000) AS g(i) ORDER BY i;
COMMIT;
VACUUM (ANALYZE) live5.orders;
VACUUM (ANALYZE) live5.customers;
VACUUM (ANALYZE) live5.events;
SELECT version(),current_database();
SELECT datcollate,datctype,datlocprovider FROM pg_database WHERE datname=current_database();
SELECT 'orders' AS relation,count(*) FROM live5.orders
UNION ALL SELECT 'customers',count(*) FROM live5.customers
UNION ALL SELECT 'events',count(*) FROM live5.events;

SELECT count(*) AS initial_indexes FROM pg_indexes WHERE schemaname='live5';

\set ON_ERROR_STOP on
BEGIN;
INSERT INTO hw08.orders
SELECT g,CASE WHEN g<=60000 THEN 1 ELSE 2+(g%100) END,
       CASE WHEN g%11=0 THEN 'pending' ELSE 'paid' END,
       100+(g%50000),timestamptz '2026-10-01 00:00+00'+g*interval '1 second',
       repeat(md5(g::text),5)
FROM generate_series(1,120000) g;
INSERT INTO hw08.events
SELECT g,repeat(md5(g::text),6) FROM generate_series(1,20000) g;
COMMIT;
VACUUM (ANALYZE) hw08.orders;
VACUUM (ANALYZE) hw08.events;
-- Pre-register exact shapes before the first statistics snapshot.
\ir queries.sql
SELECT total_cents FROM hw08.orders WHERE id=42;
\ir fixtures/history.sql

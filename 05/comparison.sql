\set ON_ERROR_STOP on
SET TIME ZONE 'UTC';
\if :{?index_file}
\else
\set index_file 01-indexes.sql
\endif
-- OVER() нумерует поток из упорядоченного подзапроса; не пересортировывайте его снаружи.
-- Новая сессия и свежая база. index_file можно задать через psql -v.

CREATE TEMP TABLE hw05_before_qf1 AS
SELECT row_number() OVER() AS position,q.* FROM (SELECT id,created_at,status,total_amount FROM hw05.orders WHERE store_id=1 AND created_at>=timestamptz '2026-01-02 00:00:00+00' ORDER BY created_at DESC,id DESC LIMIT 20) q;

CREATE TEMP TABLE hw05_before_qf42 AS
SELECT row_number() OVER() AS position,q.* FROM (SELECT id,created_at,status,total_amount FROM hw05.orders WHERE store_id=42 AND created_at>=timestamptz '2026-01-02 00:00:00+00' ORDER BY created_at DESC,id DESC LIMIT 20) q;

CREATE TEMP TABLE hw05_before_qw1 AS
SELECT row_number() OVER() AS position,q.* FROM (SELECT id,created_at FROM hw05.orders WHERE store_id=1 AND status='pending' ORDER BY created_at,id LIMIT 20) q;

CREATE TEMP TABLE hw05_before_qw42 AS
SELECT row_number() OVER() AS position,q.* FROM (SELECT id,created_at FROM hw05.orders WHERE store_id=42 AND status='pending' ORDER BY created_at,id LIMIT 20) q;

CREATE TEMP TABLE hw05_before_qe AS
SELECT id,email FROM hw05.customers WHERE lower(email)='user4242@example.test';

CREATE TEMP TABLE hw05_before_qj AS
SELECT id FROM hw05.orders WHERE metadata @> '{"segment":"vip"}'::jsonb;

CREATE TEMP TABLE hw05_before_qc AS
SELECT id FROM hw05.orders WHERE metadata ? 'coupon';

CREATE TEMP TABLE hw05_before_qt AS
SELECT count(*) FROM hw05.events WHERE occurred_at>=timestamptz '2026-01-03 00:00:00+00' AND occurred_at<timestamptz '2026-01-03 01:00:00+00';

CREATE TEMP TABLE hw05_before_qpage AS
SELECT row_number() OVER() AS position,q.* FROM (SELECT id,created_at,status,total_amount FROM hw05.orders WHERE store_id=1 AND created_at>=timestamptz '2026-01-02 00:00:00+00' ORDER BY created_at DESC,id DESC LIMIT 20 OFFSET 5000) q;

\ir :index_file

CREATE TEMP TABLE hw05_after_qf1 AS
SELECT row_number() OVER() AS position,q.* FROM (SELECT id,created_at,status,total_amount FROM hw05.orders WHERE store_id=1 AND created_at>=timestamptz '2026-01-02 00:00:00+00' ORDER BY created_at DESC,id DESC LIMIT 20) q;

CREATE TEMP TABLE hw05_after_qf42 AS
SELECT row_number() OVER() AS position,q.* FROM (SELECT id,created_at,status,total_amount FROM hw05.orders WHERE store_id=42 AND created_at>=timestamptz '2026-01-02 00:00:00+00' ORDER BY created_at DESC,id DESC LIMIT 20) q;

CREATE TEMP TABLE hw05_after_qw1 AS
SELECT row_number() OVER() AS position,q.* FROM (SELECT id,created_at FROM hw05.orders WHERE store_id=1 AND status='pending' ORDER BY created_at,id LIMIT 20) q;

CREATE TEMP TABLE hw05_after_qw42 AS
SELECT row_number() OVER() AS position,q.* FROM (SELECT id,created_at FROM hw05.orders WHERE store_id=42 AND status='pending' ORDER BY created_at,id LIMIT 20) q;

CREATE TEMP TABLE hw05_after_qe AS
SELECT id,email FROM hw05.customers WHERE lower(email)='user4242@example.test';

CREATE TEMP TABLE hw05_after_qj AS
SELECT id FROM hw05.orders WHERE metadata @> '{"segment":"vip"}'::jsonb;

CREATE TEMP TABLE hw05_after_qc AS
SELECT id FROM hw05.orders WHERE metadata ? 'coupon';

CREATE TEMP TABLE hw05_after_qt AS
SELECT count(*) FROM hw05.events WHERE occurred_at>=timestamptz '2026-01-03 00:00:00+00' AND occurred_at<timestamptz '2026-01-03 01:00:00+00';

CREATE TEMP TABLE hw05_after_qpage AS
SELECT row_number() OVER() AS position,q.* FROM (SELECT id,created_at,status,total_amount FROM hw05.orders WHERE store_id=1 AND created_at>=timestamptz '2026-01-02 00:00:00+00' ORDER BY created_at DESC,id DESC LIMIT 20 OFFSET 5000) q;

-- Сверяем также названия и типы колонок, включая typmod (точность numeric и т. п.).
DO $$
DECLARE label text; before_cols jsonb; after_cols jsonb;
BEGIN
  FOREACH label IN ARRAY ARRAY['qf1','qf42','qw1','qw42','qe','qj','qc','qt','qpage'] LOOP
    SELECT jsonb_agg(jsonb_build_array(attname,atttypid,atttypmod) ORDER BY attnum)
      INTO before_cols FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.hw05_before_'||label) AND attnum>0 AND NOT attisdropped;
    SELECT jsonb_agg(jsonb_build_array(attname,atttypid,atttypmod) ORDER BY attnum)
      INTO after_cols FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.hw05_after_'||label) AND attnum>0 AND NOT attisdropped;
    IF before_cols IS DISTINCT FROM after_cols THEN RAISE EXCEPTION 'Column contract differs: %',label; END IF;
  END LOOP;
END $$;

CREATE TEMP TABLE hw05_differences AS
SELECT 'QF1' AS query_name,count(*) AS changed_rows FROM ((SELECT * FROM hw05_before_qf1 EXCEPT ALL SELECT * FROM hw05_after_qf1) UNION ALL (SELECT * FROM hw05_after_qf1 EXCEPT ALL SELECT * FROM hw05_before_qf1)) difference
UNION ALL
SELECT 'QF42' AS query_name,count(*) AS changed_rows FROM ((SELECT * FROM hw05_before_qf42 EXCEPT ALL SELECT * FROM hw05_after_qf42) UNION ALL (SELECT * FROM hw05_after_qf42 EXCEPT ALL SELECT * FROM hw05_before_qf42)) difference
UNION ALL
SELECT 'QW1' AS query_name,count(*) AS changed_rows FROM ((SELECT * FROM hw05_before_qw1 EXCEPT ALL SELECT * FROM hw05_after_qw1) UNION ALL (SELECT * FROM hw05_after_qw1 EXCEPT ALL SELECT * FROM hw05_before_qw1)) difference
UNION ALL
SELECT 'QW42' AS query_name,count(*) AS changed_rows FROM ((SELECT * FROM hw05_before_qw42 EXCEPT ALL SELECT * FROM hw05_after_qw42) UNION ALL (SELECT * FROM hw05_after_qw42 EXCEPT ALL SELECT * FROM hw05_before_qw42)) difference
UNION ALL
SELECT 'QE' AS query_name,count(*) AS changed_rows FROM ((SELECT * FROM hw05_before_qe EXCEPT ALL SELECT * FROM hw05_after_qe) UNION ALL (SELECT * FROM hw05_after_qe EXCEPT ALL SELECT * FROM hw05_before_qe)) difference
UNION ALL
SELECT 'QJ' AS query_name,count(*) AS changed_rows FROM ((SELECT * FROM hw05_before_qj EXCEPT ALL SELECT * FROM hw05_after_qj) UNION ALL (SELECT * FROM hw05_after_qj EXCEPT ALL SELECT * FROM hw05_before_qj)) difference
UNION ALL
SELECT 'QC' AS query_name,count(*) AS changed_rows FROM ((SELECT * FROM hw05_before_qc EXCEPT ALL SELECT * FROM hw05_after_qc) UNION ALL (SELECT * FROM hw05_after_qc EXCEPT ALL SELECT * FROM hw05_before_qc)) difference
UNION ALL
SELECT 'QT' AS query_name,count(*) AS changed_rows FROM ((SELECT * FROM hw05_before_qt EXCEPT ALL SELECT * FROM hw05_after_qt) UNION ALL (SELECT * FROM hw05_after_qt EXCEPT ALL SELECT * FROM hw05_before_qt)) difference
UNION ALL
SELECT 'QPAGE' AS query_name,count(*) AS changed_rows FROM ((SELECT * FROM hw05_before_qpage EXCEPT ALL SELECT * FROM hw05_after_qpage) UNION ALL (SELECT * FROM hw05_after_qpage EXCEPT ALL SELECT * FROM hw05_before_qpage)) difference;
TABLE hw05_differences;
DO $$ BEGIN IF EXISTS(SELECT 1 FROM hw05_differences WHERE changed_rows<>0) THEN RAISE EXCEPTION 'Results differ'; END IF; END $$;
\echo PASS: full results and required order preserved

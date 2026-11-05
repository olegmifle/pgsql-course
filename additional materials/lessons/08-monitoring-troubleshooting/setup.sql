\set ON_ERROR_STOP on
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='monitor') THEN
    CREATE ROLE monitor LOGIN PASSWORD 'monitor-local-only' CONNECTION LIMIT 2;
  END IF;
END $$;
GRANT pg_monitor TO monitor;
ALTER ROLE monitor SET default_transaction_read_only=on;
ALTER ROLE monitor SET statement_timeout='5s';
ALTER ROLE monitor SET lock_timeout='500ms';
DROP SCHEMA IF EXISTS incident08 CASCADE;
CREATE SCHEMA incident08;
CREATE TABLE incident08.orders (
  id bigint PRIMARY KEY,
  tenant_id integer NOT NULL,
  status text NOT NULL,
  total_cents integer NOT NULL,
  created_at timestamptz NOT NULL,
  note text NOT NULL
);
INSERT INTO incident08.orders
SELECT g, 1+(g%100), CASE WHEN g%11=0 THEN 'pending' ELSE 'paid' END,
       100+(g%50000), timestamptz '2026-10-01 00:00+00'+g*interval '1 second',
       repeat(md5(g::text),5)
FROM generate_series(1,120000) g;
CREATE TABLE incident08.events (
  id bigint PRIMARY KEY,
  body text NOT NULL
) WITH (autovacuum_enabled=false);
-- Only this throwaway relation disables autovacuum: deterministic horizon experiment.
INSERT INTO incident08.events SELECT g,repeat(md5(g::text),6) FROM generate_series(1,20000) g;
VACUUM (ANALYZE) incident08.orders;
VACUUM (ANALYZE) incident08.events;
-- Register both exact query shapes before taking the pgss baseline.
SELECT id, total_cents FROM incident08.orders
WHERE tenant_id=7 AND status='pending'
ORDER BY created_at DESC, id DESC LIMIT 20;
SELECT total_cents FROM incident08.orders WHERE id=42;
SELECT 'ready' AS lab, version();

\set ON_ERROR_STOP on
BEGIN;
-- A repeated installation fails here and rolls back, without deleting your work.
CREATE SCHEMA hw08;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE TABLE hw08.orders (
  id bigint PRIMARY KEY,
  tenant_id integer NOT NULL,
  status text NOT NULL CHECK (status IN ('pending','paid')),
  total_cents integer NOT NULL CHECK (total_cents>=0),
  created_at timestamptz NOT NULL,
  note text NOT NULL
);
CREATE TABLE hw08.events (
  id bigint PRIMARY KEY,
  body text NOT NULL
) WITH (autovacuum_enabled=false);
-- Only this throwaway relation disables autovacuum for a deterministic exercise.
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='hw08_monitor') THEN
    CREATE ROLE hw08_monitor LOGIN PASSWORD 'monitor_local' CONNECTION LIMIT 3;
  END IF;
END $$;
GRANT pg_monitor TO hw08_monitor;
GRANT USAGE ON SCHEMA hw08 TO hw08_monitor;
ALTER ROLE hw08_monitor SET default_transaction_read_only=on;
ALTER ROLE hw08_monitor SET statement_timeout='5s';
ALTER ROLE hw08_monitor SET lock_timeout='500ms';
COMMIT;

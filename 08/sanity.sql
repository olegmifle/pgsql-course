\set ON_ERROR_STOP on
DO $$ BEGIN
  IF current_setting('server_version_num')::int NOT BETWEEN 180000 AND 189999 THEN
    RAISE EXCEPTION 'FAIL: package targets PostgreSQL 18';
  END IF;
  IF (SELECT count(*) FROM hw08.orders)<>120000 OR
     (SELECT count(*) FROM hw08.events)<>20000 THEN
    RAISE EXCEPTION 'FAIL: initial counts differ; use a fresh database';
  END IF;
  IF NOT EXISTS (SELECT FROM pg_extension WHERE extname='pg_stat_statements') THEN
    RAISE EXCEPTION 'FAIL: pg_stat_statements is missing';
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='hw08_monitor') THEN
    RAISE EXCEPTION 'FAIL: monitor role is missing';
  END IF;
END $$;
SELECT 'PASS: initial fixture only; diagnostic solution is not checked' AS result;
SELECT current_database(),version(),pg_postmaster_start_time();

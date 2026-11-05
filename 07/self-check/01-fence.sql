\set ON_ERROR_STOP on
-- Передайте -v min_lsn=... -v order_id=1001. Выполняйте на r1/r2 из НОВОГО подключения.
-- Один пробный барьер с ранним отказом; общий deadline клиент задаёт снаружи.
BEGIN ISOLATION LEVEL READ COMMITTED READ ONLY;
SET LOCAL statement_timeout='1s';
SELECT pg_is_in_recovery() AND
  coalesce(pg_last_wal_replay_lsn()>=:'min_lsn'::pg_lsn,false) AS fence_ready \gset
COMMIT;
\if :fence_ready
  BEGIN ISOLATION LEVEL READ COMMITTED READ ONLY;
  SET LOCAL statement_timeout='1s';
  SELECT id,status,external_token FROM hw07.orders WHERE id=:'order_id'::bigint;
  COMMIT;
\else
  DO $$ BEGIN
    RAISE EXCEPTION 'freshness_timeout: replay has not reached requested LSN'
      USING ERRCODE='P0001';
  END $$;
\endif

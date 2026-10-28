\set ON_ERROR_STOP on
-- Перед возвратом запись приостановлена, новый тариф ещё выключен.
BEGIN;
SET LOCAL lock_timeout = '2s';
ALTER TABLE hw04.orders ALTER COLUMN total_amount DROP NOT NULL;
ALTER TABLE hw04.orders
    DROP CONSTRAINT amount_present,
    DROP CONSTRAINT amount_matches_cents;
COMMIT;
-- Диапазон новой суммы, составной FK и UNIQUE номера остаются.
-- Старая версия снова читает и меняет total_cents; total_amount может устареть.

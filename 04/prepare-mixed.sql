\set ON_ERROR_STOP on
-- Запустить один раз после 03-expand.sql.
BEGIN;
-- Операция переходной версии приложения.
UPDATE hw04.orders SET total_cents = 150000, total_amount = 1500.0000
WHERE id = 1001;
-- Одна порция переноса существующих сумм в новую колонку.
UPDATE hw04.orders SET total_amount = total_cents::numeric / 100
WHERE id IN (1001, 1002) AND total_amount IS NULL;
-- Следующий запуск прежнего ночного импорта.
UPDATE hw04.orders SET total_cents = 60000 WHERE id = 1002;
COMMIT;
SELECT id, total_cents, total_amount FROM hw04.orders ORDER BY id;

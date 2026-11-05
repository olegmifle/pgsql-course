\set ON_ERROR_STOP on
-- В изолированном L2 publisher владеет общими данными; локальная draft ошибочна.
BEGIN;
CREATE TABLE IF NOT EXISTS hw07.receipt_repair(
  order_id bigint PRIMARY KEY,receipt_token uuid NOT NULL
);
INSERT INTO hw07.receipt_repair
SELECT id,receipt_token FROM hw07.orders WHERE id=1201 AND status='draft'
ON CONFLICT(order_id) DO NOTHING;
DELETE FROM hw07.orders WHERE id=1201 AND status='draft';
COMMIT;
-- Чтение этих ключей закрыто до finish. Дождитесь paid 1201, 1202 и progress 1203,
-- затем выполните 02-conflict-finish.sql: он вернёт сохранённый локальный token.

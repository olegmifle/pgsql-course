\set ON_ERROR_STOP on
-- Выполните один раз после исходных замеров: обновление служебной метки заказов.
UPDATE hw05.orders SET payload=overlay(payload placing 'sync' from 1 for 4)
WHERE store_id=42 OR (store_id=1 AND id>148000);
-- Autocommit завершён. Поля исходных SELECT не меняются, страницы изменились.

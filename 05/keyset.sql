\set ON_ERROR_STOP on
SET TIME ZONE 'UTC';
-- Контрольный курсор для страницы OFFSET 5000. Измеряйте его подготовку отдельно.
SELECT created_at AS last_time,id AS last_id FROM hw05.orders
WHERE store_id=1 AND created_at>=timestamptz '2026-01-02 00:00:00+00'
ORDER BY created_at DESC,id DESC LIMIT 1 OFFSET 4999
\gset cursor_
-- Напишите SELECT следующей страницы с использованием cursor_last_time/cursor_last_id.
-- Сохраните фильтр начала периода, значения и порядок QPAGE.
-- Проверьте также границу первой страницы: в данных есть одинаковое время.

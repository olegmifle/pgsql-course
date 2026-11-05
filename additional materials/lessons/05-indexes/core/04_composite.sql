\set ON_ERROR_STOP on
\ir ../_display.sql
DROP INDEX IF EXISTS live5.orders_feed_idx;
DROP INDEX IF EXISTS live5.orders_feed_cover_idx;
DROP INDEX IF EXISTS live5.orders_range_status_idx;
DROP INDEX IF EXISTS live5.orders_status_range_idx;
DROP INDEX IF EXISTS live5.orders_pending_idx;
\echo ''
\echo '4.1 Заказы магазина 1: диапазон и статус'
\ir ../_pause.sql
\ir ../show/13_pending_count.sql
\echo ''
\echo '4.2 Время перед статусом'
\ir ../_pause.sql
\ir ../show/14_time_status_index.sql
\ir ../show/13_pending_count.sql
\echo ''
\echo '4.3 Статус перед временем; общая лента'
\ir ../_pause.sql
\ir ../show/15_status_time_index.sql
\ir ../show/13_pending_count.sql
\ir ../show/16_feed_query.sql
\echo ''
\echo '4.4 Ключ общей ленты и следующая страница'
\ir ../_pause.sql
\ir ../show/17_feed_index.sql
\ir ../show/16_feed_query.sql
SELECT created_at AS last_time,id AS last_id FROM orders
WHERE store_id=1 AND created_at>=timestamptz '2026-01-03 00:00:00+00'
ORDER BY created_at DESC,id DESC LIMIT 1 OFFSET 19 \gset
\echo 'Курсор из последнего заказа первой страницы:' :last_time :last_id
\ir ../show/18_keyset.sql

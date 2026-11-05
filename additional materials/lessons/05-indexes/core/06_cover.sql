\set ON_ERROR_STOP on
\ir ../_display.sql
DROP INDEX IF EXISTS live5.orders_feed_cover_idx;
CREATE INDEX IF NOT EXISTS orders_feed_idx ON orders(store_id,created_at DESC,id DESC);
\echo ''
\echo '6.1 Лента без INCLUDE'
\ir ../_pause.sql
\ir ../show/22_cover_query.sql
\echo ''
\echo '6.2 Покрытие после VACUUM'
\ir ../_pause.sql
\ir ../show/23_cover_index.sql
\ir ../show/25_vacuum.sql
\ir ../show/22_cover_query.sql
\echo ''
\echo '6.3 Обновление служебного поля'
\ir ../_pause.sql
-- Сохраняем состояние страниц до следующей остановки. В конце возвращаем autovacuum.
ALTER TABLE orders SET (autovacuum_enabled=false);
\ir ../show/24_update_payload.sql
\ir ../show/22_cover_query.sql
\echo ''
\echo '6.4 Повтор после VACUUM'
\ir ../_pause.sql
\ir ../show/25_vacuum.sql
\ir ../show/22_cover_query.sql
ALTER TABLE orders RESET (autovacuum_enabled);

\set ON_ERROR_STOP on
\ir ../_display.sql
DROP INDEX IF EXISTS live5.orders_pending_idx;
DROP INDEX IF EXISTS live5.orders_status_range_idx;
\echo ''
\echo '5.1 Очередь ожидающих заказов магазина 42'
\ir ../_pause.sql
\ir ../show/19_pending_queue.sql
\echo ''
\echo '5.2 Индекс только ожидающих заказов'
\ir ../_pause.sql
\ir ../show/20_partial_index.sql
\ir ../show/19_pending_queue.sql
\ir ../show/21_index_sizes.sql

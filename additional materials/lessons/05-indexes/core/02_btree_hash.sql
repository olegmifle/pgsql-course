\set ON_ERROR_STOP on
\ir ../_display.sql
DROP INDEX IF EXISTS live5.qr_ind;
DROP INDEX IF EXISTS live5.qr_ind_hash;
DROP INDEX IF EXISTS live5.orders_qr_like_idx;
DROP INDEX IF EXISTS live5.orders_qr_trgm_idx;
SELECT qr AS sample_qr FROM orders WHERE id=4242 \gset
\echo 'QR существующего заказа:' :sample_qr
\echo ''
\echo '2.1 Равенство без индекса'
\ir ../_pause.sql
\ir ../show/04_qr_equal.sql
\echo ''
\echo '2.2 B-tree: равенство и диапазон'
\ir ../_pause.sql
\ir ../show/05_qr_btree.sql
\ir ../show/04_qr_equal.sql
\ir ../show/06_qr_range.sql
\echo ''
\echo '2.3 Сравнение с отключённым Seq Scan внутри транзакции'
\ir ../_pause.sql
\ir ../show/07_force_comparison.sql
\echo ''
\echo '2.4 Hash: равенство и диапазон'
\ir ../_pause.sql
\ir ../show/08_qr_hash.sql
\ir ../show/04_qr_equal.sql
\ir ../show/06_qr_range.sql

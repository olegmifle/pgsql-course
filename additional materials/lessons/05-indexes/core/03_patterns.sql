\set ON_ERROR_STOP on
\ir ../_display.sql
DROP INDEX IF EXISTS live5.qr_ind;
DROP INDEX IF EXISTS live5.qr_ind_hash;
DROP INDEX IF EXISTS live5.orders_qr_like_idx;
DROP INDEX IF EXISTS live5.orders_qr_trgm_idx;
SELECT left(qr,4) AS qr_prefix,substr(qr,7,8) AS qr_fragment FROM orders WHERE id=4242 \gset
\echo 'Префикс:' :qr_prefix 'Фрагмент:' :qr_fragment
\ir ../show/05_qr_btree.sql
\echo ''
\echo '3.1 Префикс с обычным B-tree'
\ir ../_pause.sql
\ir ../show/09_prefix.sql
\echo ''
\echo '3.2 Префикс с text_pattern_ops'
\ir ../_pause.sql
\ir ../show/10_pattern_index.sql
\ir ../show/09_prefix.sql
\echo ''
\echo '3.3 Обычный диапазон и подстрока'
\ir ../_pause.sql
DROP INDEX live5.qr_ind;
\ir ../show/06_qr_range.sql
\ir ../show/11_substring.sql
\echo ''
\echo '3.4 Подстрока с pg_trgm'
\ir ../_pause.sql
\ir ../show/12_trigram_index.sql
\ir ../show/11_substring.sql

\set ON_ERROR_STOP on
\ir ../_display.sql
DROP INDEX IF EXISTS live5.price_ind;
\echo ''
\echo '1.1 Цена < 50: до индекса'
\ir ../_pause.sql
\ir ../show/01_price_query.sql
\echo ''
\echo '1.2 Индекс по цене'
\ir ../_pause.sql
\ir ../show/02_price_index.sql
\ir ../show/01_price_query.sql
SELECT count(*) AS matching_orders FROM orders WHERE price<50;
\echo ''
\echo '1.3 Широкая выборка'
\ir ../_pause.sql
\ir ../show/03_price_wide.sql

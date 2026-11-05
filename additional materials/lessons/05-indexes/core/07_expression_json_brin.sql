\set ON_ERROR_STOP on
\ir ../_display.sql
DROP INDEX IF EXISTS live5.customers_email_idx;
DROP INDEX IF EXISTS live5.orders_metadata_idx;
DROP INDEX IF EXISTS live5.events_time_idx;
\echo ''
\echo '7.1 Expression: поиск покупателя по email'
\ir ../_pause.sql
\ir ../show/26_email_query.sql
\ir ../show/27_email_index.sql
\ir ../show/26_email_query.sql
\echo ''
\echo '7.2 GIN: сегмент покупателя в JSONB'
\ir ../_pause.sql
\ir ../show/28_json_query.sql
\ir ../show/29_json_index.sql
\ir ../show/28_json_query.sql
\echo ''
\echo '7.3 BRIN: час событий в упорядоченной таблице'
\ir ../_pause.sql
\ir ../show/30_events_query.sql
\ir ../show/31_brin_index.sql
\ir ../show/30_events_query.sql

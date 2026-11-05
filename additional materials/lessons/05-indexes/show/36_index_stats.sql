SELECT schemaname, relname, indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes WHERE schemaname = 'live5' ORDER BY relname, indexrelname;
SELECT pg_size_pretty(pg_indexes_size('live5.orders')) AS orders_indexes;
SELECT indexname, indexdef FROM pg_indexes
WHERE schemaname = 'live5' ORDER BY tablename, indexname;

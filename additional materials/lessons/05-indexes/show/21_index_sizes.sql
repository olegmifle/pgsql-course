SELECT count(*) AS pending_orders FROM orders WHERE status = 'pending';
SELECT indexrelid::regclass AS index_name,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_index WHERE indrelid = 'live5.orders'::regclass
ORDER BY indexrelid::regclass::text;

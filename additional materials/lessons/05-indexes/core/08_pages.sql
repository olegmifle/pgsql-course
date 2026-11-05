\set ON_ERROR_STOP on
\ir ../_display.sql
SELECT root AS bt_root FROM bt_metap('live5.orders_pkey') \gset
\echo ''
\echo '8.1 JSON-план, метастраница и корень B-tree'
\ir ../_pause.sql
\ir ../show/32_json_plan.sql
\ir ../show/33_btree_root.sql
SELECT g.blk AS bt_leaf
FROM generate_series(1,pg_relation_size('live5.orders_pkey')/current_setting('block_size')::int-1) AS g(blk)
CROSS JOIN LATERAL bt_page_stats('live5.orders_pkey',g.blk) AS s
WHERE s.type='l' AND s.live_items>0 LIMIT 1 \gset
\echo ''
\echo '8.2 Лист B-tree'
\ir ../_pause.sql
\ir ../show/34_btree_leaf.sql
CREATE INDEX IF NOT EXISTS qr_ind_hash ON orders USING hash(qr);
SELECT g.blk AS hash_bucket
FROM generate_series(1,pg_relation_size('live5.qr_ind_hash')/current_setting('block_size')::int-1) AS g(blk)
WHERE hash_page_type(get_raw_page('live5.qr_ind_hash',g.blk))='bucket'
LIMIT 1 \gset
\echo ''
\echo '8.3 Hash bucket и статистика индексов'
\ir ../_pause.sql
\ir ../show/35_hash_bucket.sql
\ir ../show/36_index_stats.sql

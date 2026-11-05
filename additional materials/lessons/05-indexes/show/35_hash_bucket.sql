SELECT * FROM hash_page_stats(get_raw_page('live5.qr_ind_hash', :hash_bucket));
SELECT * FROM hash_page_items(get_raw_page('live5.qr_ind_hash', :hash_bucket)) LIMIT 8;

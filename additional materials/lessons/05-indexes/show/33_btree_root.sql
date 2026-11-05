SELECT * FROM bt_metap('live5.orders_pkey');
SELECT * FROM bt_page_stats('live5.orders_pkey', :bt_root);
SELECT * FROM bt_page_items('live5.orders_pkey', :bt_root) LIMIT 8;

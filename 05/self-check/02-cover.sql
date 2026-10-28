\set ON_ERROR_STOP on
CREATE INDEX orders_cover_idx ON hw05.orders(store_id,created_at DESC,id DESC) INCLUDE(status,total_amount);
CREATE INDEX orders_status_idx ON hw05.orders(store_id,status,created_at,id);
CREATE INDEX customers_email_idx ON hw05.customers(lower(email));
CREATE INDEX orders_metadata_idx ON hw05.orders USING gin(metadata);
CREATE INDEX events_time_idx ON hw05.events USING brin(occurred_at) WITH(pages_per_range=32);
SELECT brin_summarize_new_values('hw05.events_time_idx'::regclass);
DROP INDEX hw05.orders_store_idx;

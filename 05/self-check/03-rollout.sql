\set ON_ERROR_STOP on
-- Пример замены одного исходного индекса в свежей базе. Выполнять вне BEGIN.
CREATE INDEX CONCURRENTLY orders_feed_release_idx
ON hw05.orders(store_id,created_at DESC,id DESC);
SELECT c.relname,i.indisready,i.indisvalid FROM pg_index i JOIN pg_class c ON c.oid=i.indexrelid
WHERE i.indexrelid='hw05.orders_feed_release_idx'::regclass;
-- После проверки планов и остальных запросов, использовавших старый индекс:
DROP INDEX CONCURRENTLY hw05.orders_store_idx;

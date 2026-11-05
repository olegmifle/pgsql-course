-- сессия изменений. Транзакция сессии чтения остаётся открытой; wal_demo независима от таблицы versions.
CHECKPOINT;
SELECT pg_current_wal_insert_lsn() AS wal_before \gset
BEGIN;
UPDATE underhood.wal_demo SET counter=counter+1 WHERE id=1
RETURNING xmin::text AS wal_xid \gset
COMMIT;
SELECT pg_current_wal_flush_lsn() AS wal_after \gset
SELECT :'wal_before'::pg_lsn AS wal_before,
       :'wal_after'::pg_lsn AS wal_after,
       pg_wal_lsn_diff(:'wal_after'::pg_lsn,:'wal_before'::pg_lsn)
         AS wal_bytes_in_interval;

SELECT start_lsn, end_lsn, xid, resource_manager, record_type,
       record_length, fpi_length, description, block_ref
FROM pg_get_wal_records_info(:'wal_before'::pg_lsn,:'wal_after'::pg_lsn)
WHERE xid::text=:'wal_xid'
ORDER BY start_lsn;

-- Сравнить конец фактической записи COMMIT с позицией сброса WAL.
SELECT end_lsn AS commit_end
FROM pg_get_wal_records_info(:'wal_before'::pg_lsn,:'wal_after'::pg_lsn)
WHERE xid::text=:'wal_xid'
  AND resource_manager='Transaction' AND record_type='COMMIT'
ORDER BY start_lsn DESC LIMIT 1 \gset
SELECT :'commit_end'::pg_lsn AS commit_end,
       pg_current_wal_flush_lsn() AS flush_lsn,
       pg_current_wal_flush_lsn() >= :'commit_end'::pg_lsn
         AS commit_record_is_flushed;
SELECT * FROM underhood.buffer_state
WHERE relation='underhood.wal_demo'::regclass;
SELECT 'before_checkpoint' AS stage,* FROM underhood.wal_page_locations;
CHECKPOINT;
SELECT * FROM underhood.buffer_state
WHERE relation='underhood.wal_demo'::regclass;
SELECT 'after_checkpoint' AS stage,* FROM underhood.wal_page_locations;

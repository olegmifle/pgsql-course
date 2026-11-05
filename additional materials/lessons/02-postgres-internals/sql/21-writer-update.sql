-- сессия изменений. Оставить транзакцию открытой до шага 23.
SET application_name='underhood_writer';
BEGIN;
SELECT pg_current_xact_id()::text AS writer_xid \gset
\echo writer_xid = :writer_xid
UPDATE underhood.versions SET progress=40 WHERE id=1
RETURNING id, progress, ctid, xmin, xmax;
SELECT * FROM underhood.version_page;

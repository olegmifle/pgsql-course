-- сессия чтения. Сохранить подключение и оставить транзакцию открытой до шага 41.
SET application_name='underhood_reader';
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT pg_current_snapshot() AS snapshot,
       pg_snapshot_xmin(pg_current_snapshot()) AS xmin,
       pg_snapshot_xmax(pg_current_snapshot()) AS xmax;
SELECT id, progress, ctid, xmin, xmax FROM underhood.versions;

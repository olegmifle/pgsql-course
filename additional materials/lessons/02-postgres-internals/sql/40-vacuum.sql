-- сессия изменений. Сначала с открытой сессией чтения, затем повторить после шага 41.
SELECT pid,application_name,state,backend_xmin,
       clock_timestamp()-xact_start AS xact_age
FROM pg_stat_activity
WHERE application_name IN ('underhood_reader','underhood_writer')
  AND datname=current_database()
ORDER BY application_name;

SELECT 'before_vacuum' AS stage,* FROM underhood.version_page;
SELECT pg_relation_size('underhood.versions') AS heap_bytes_before;
VACUUM (VERBOSE,ANALYZE,TRUNCATE FALSE) underhood.versions;
SELECT 'after_vacuum' AS stage,* FROM underhood.version_page;
SELECT pg_relation_size('underhood.versions') AS heap_bytes_after;

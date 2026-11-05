-- Сессия изменений, после опыта с версиями и COMMIT сессии чтения.
ALTER TABLE underhood.buffer_demo RESET (autovacuum_enabled);
ALTER TABLE underhood.versions RESET (autovacuum_enabled);
SELECT c.oid::regclass AS relation,c.reloptions
FROM pg_class AS c
WHERE c.oid IN ('underhood.buffer_demo'::regclass,
                'underhood.versions'::regclass);

-- psql client-side generation: 12 separate feed calls and 80 point reads.
-- No artificial pg_sleep: rankings and times depend on the local machine.
\o /dev/null
SELECT 'SELECT id, total_cents FROM incident08.orders WHERE tenant_id=7 AND status=''pending'' ORDER BY created_at DESC, id DESC LIMIT 20;' FROM generate_series(1,12)
\gexec
SELECT format('SELECT total_cents FROM incident08.orders WHERE id=%s;',g) FROM generate_series(1,80) g
\gexec
\o
SELECT '12 feed calls + 80 point reads finished' AS workload;

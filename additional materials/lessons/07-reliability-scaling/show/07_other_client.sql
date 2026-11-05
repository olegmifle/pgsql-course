BEGIN;
SELECT pg_backend_pid(), current_setting('app.tenant_id', true);
COMMIT;

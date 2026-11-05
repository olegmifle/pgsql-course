BEGIN;
SET LOCAL app.tenant_id = '7';
SELECT pg_backend_pid(), current_setting('app.tenant_id');
COMMIT;

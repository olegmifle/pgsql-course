BEGIN;
SET app.tenant_id = '42';
SELECT pg_backend_pid(), current_setting('app.tenant_id');
COMMIT;

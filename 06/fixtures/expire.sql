\set ON_ERROR_STOP on
-- Вызов из psql: \set job_id 1 затем \i /work/fixtures/expire.sql
-- Это административное управление временем опыта, не код рабочего воркера.
UPDATE hw06.jobs SET lease_until=clock_timestamp()-interval '1 second'
WHERE id=:'job_id'::bigint AND status='running'
RETURNING id,claim_version,worker_id,lease_until;

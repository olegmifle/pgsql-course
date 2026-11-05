\set ON_ERROR_STOP on
DROP TRIGGER IF EXISTS inject_outbox_error ON hw06.jobs;
DROP FUNCTION IF EXISTS hw06.fail_job();

\set ON_ERROR_STOP on
CREATE OR REPLACE FUNCTION hw06.fail_job() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'Учебный отказ записи задания' USING ERRCODE='P0001'; END $$;
CREATE TRIGGER inject_outbox_error BEFORE INSERT ON hw06.jobs
FOR EACH ROW EXECUTE FUNCTION hw06.fail_job();

\set ON_ERROR_STOP on
-- Включает контролируемый отказ после изменения остатка, на INSERT резерва.
CREATE OR REPLACE FUNCTION hw06.fail_reservation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'Учебный отказ записи резерва' USING ERRCODE='P0001'; END $$;
CREATE TRIGGER inject_reservation_error BEFORE INSERT ON hw06.reservations
FOR EACH ROW EXECUTE FUNCTION hw06.fail_reservation();

\set ON_ERROR_STOP on
DROP TRIGGER IF EXISTS inject_reservation_error ON hw06.reservations;
DROP FUNCTION IF EXISTS hw06.fail_reservation();

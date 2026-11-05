\set ON_ERROR_STOP on
-- Пересоздаёт ТОЛЬКО отдельную учебную схему live06 в выбранной базе.
BEGIN;
DROP SCHEMA IF EXISTS live06 CASCADE;
CREATE SCHEMA live06;
SET LOCAL search_path=live06,public;
CREATE TABLE stock(sku integer PRIMARY KEY, available integer NOT NULL CHECK(available>=0));
INSERT INTO stock VALUES(42,1);
CREATE TABLE reservations(
 request_id text PRIMARY KEY, sku integer NOT NULL REFERENCES stock,
 qty integer NOT NULL CHECK(qty>0)
);
CREATE TABLE quota_reservations(id integer PRIMARY KEY,organization_id integer NOT NULL,active boolean NOT NULL);
INSERT INTO quota_reservations SELECT n,7,true FROM generate_series(1,4)n;
CREATE TABLE on_call(doctor_id integer PRIMARY KEY,shift_id integer NOT NULL,active boolean NOT NULL);
INSERT INTO on_call VALUES(1,1,true),(2,1,true);
COMMIT;
SELECT 'READY: live06, SKU 42 = 1, active reservations = 4, on-call doctors = 2' AS result;

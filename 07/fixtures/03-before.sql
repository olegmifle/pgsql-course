\set ON_ERROR_STOP on
BEGIN;
INSERT INTO hw07.lab_state VALUES('incident','started');
INSERT INTO hw07.orders(id,tenant_id,status,total_amount,created_at)
VALUES(3001,42,'created',300,'2026-11-02 12:00:00+00');
INSERT INTO hw07.order_items VALUES(3001,1,'E',3,100);
COMMIT;

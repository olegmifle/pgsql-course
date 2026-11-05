\set ON_ERROR_STOP on
ALTER TABLE hw07.orders ADD COLUMN currency text NOT NULL DEFAULT 'RUB';
BEGIN;
INSERT INTO hw07.orders(id,tenant_id,status,total_amount,created_at)
VALUES(1301,42,'paid',100,'2026-11-02 10:00:00+00');
INSERT INTO hw07.order_items VALUES(1301,1,'L3',1,100);
COMMIT;
INSERT INTO hw07.progress VALUES(1302,'after currency');

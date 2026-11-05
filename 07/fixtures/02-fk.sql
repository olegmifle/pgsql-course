\set ON_ERROR_STOP on
INSERT INTO hw07.tenants VALUES(99,'Новый магазин');
BEGIN;
INSERT INTO hw07.orders(id,tenant_id,status,total_amount,created_at)
VALUES(1401,99,'paid',100,'2026-11-02 11:00:00+00');
INSERT INTO hw07.order_items VALUES(1401,1,'L4',1,100);
COMMIT;
INSERT INTO hw07.progress VALUES(1402,'after new tenant');

\set ON_ERROR_STOP on
BEGIN;
DELETE FROM hw07.orders WHERE tenant_id=42;
COMMIT;
BEGIN;
UPDATE hw07.orders SET status='cancelled' WHERE id=2001;
INSERT INTO hw07.orders(id,tenant_id,status,total_amount,created_at)
VALUES(3002,7,'paid',80,'2026-11-02 13:00:00+00');
INSERT INTO hw07.order_items VALUES(3002,1,'F',2,40);
COMMIT;

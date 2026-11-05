\set ON_ERROR_STOP on
\connect course_hw07 course 127.0.0.1 5544
INSERT INTO hw07.orders(id,tenant_id,status,total_amount,created_at,external_token)
VALUES(1201,42,'draft',1,'2026-11-02 09:00:00+00','00000000-0000-0000-0000-000000001201');
\connect course_hw07 course 127.0.0.1 5540
BEGIN;
INSERT INTO hw07.orders(id,tenant_id,status,total_amount,created_at) VALUES
  (1201,42,'paid',80,'2026-11-02 09:00:00+00'),
  (1202,7,'created',90,'2026-11-02 09:01:00+00');
INSERT INTO hw07.order_items VALUES(1201,1,'L2-A',1,80),(1202,1,'L2-B',1,90);
COMMIT;
INSERT INTO hw07.progress VALUES(1203,'a later transaction');

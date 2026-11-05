\set ON_ERROR_STOP on
INSERT INTO hw07.tenants VALUES(42,'Магазин 42'),(7,'Магазин 7');
INSERT INTO hw07.orders(id,tenant_id,status,total_amount,created_at) VALUES
  (1001,42,'created',120.00,'2026-11-01 10:00:00+00'),
  (1002,42,'paid',200.00,'2026-11-01 11:00:00+00'),
  (2001,7,'paid',75.00,'2026-11-01 12:00:00+00'),
  (2002,7,'created',50.00,'2026-11-02 00:30:00+00');
INSERT INTO hw07.order_items VALUES
  (1001,1,'A',2,60.00),(1002,1,'B',1,200.00),
  (2001,1,'C',3,25.00),(2002,1,'D',1,50.00);
INSERT INTO hw07.generated_ids(note) VALUES('first'),('second');
INSERT INTO hw07.events
SELECT g,'2026-09-01 00:00:00+00'::timestamptz+(g-1)*interval '15 minutes',
  CASE WHEN g%2=0 THEN 42 ELSE 7 END,jsonb_build_object('kind','status_changed')
FROM generate_series(1,8736) g;
ANALYZE hw07.orders;
ANALYZE hw07.events;
CREATE PUBLICATION hw07_pub FOR TABLE hw07.orders,hw07.progress,hw07.generated_ids;

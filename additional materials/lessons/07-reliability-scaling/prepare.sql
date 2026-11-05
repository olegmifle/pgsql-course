CREATE TABLE orders (id bigint PRIMARY KEY, tenant_id integer NOT NULL, status text NOT NULL);
INSERT INTO orders VALUES (1,42,'created'),(2,7,'paid');
CREATE TABLE events (
  event_id bigint NOT NULL,
  occurred_at timestamptz NOT NULL,
  tenant_id integer NOT NULL,
  payload jsonb NOT NULL,
  PRIMARY KEY (event_id,occurred_at)
) PARTITION BY RANGE (occurred_at);
CREATE TABLE events_2026_09 PARTITION OF events
FOR VALUES FROM ('2026-09-01 00:00:00+00') TO ('2026-10-01 00:00:00+00');
CREATE TABLE events_2026_10 PARTITION OF events
FOR VALUES FROM ('2026-10-01 00:00:00+00') TO ('2026-11-01 00:00:00+00');
CREATE TABLE events_2026_11 PARTITION OF events
FOR VALUES FROM ('2026-11-01 00:00:00+00') TO ('2026-12-01 00:00:00+00');
INSERT INTO events
SELECT g,'2026-09-01 00:00:00+00'::timestamptz+(g-1)*interval '4 minutes',
       CASE WHEN g%2=0 THEN 42 ELSE 7 END,jsonb_build_object('kind','order_status_changed')
FROM generate_series(1,32760) g;
CREATE INDEX events_tenant_time ON events (tenant_id,occurred_at);
ANALYZE events;

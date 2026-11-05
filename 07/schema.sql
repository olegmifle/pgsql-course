\set ON_ERROR_STOP on
CREATE SCHEMA hw07;
CREATE TABLE hw07.tenants(id int PRIMARY KEY, name text NOT NULL);
CREATE TABLE hw07.orders(
  id bigint PRIMARY KEY,
  tenant_id int NOT NULL REFERENCES hw07.tenants(id),
  status text NOT NULL CHECK(status IN ('draft','created','paid','cancelled')),
  total_amount numeric(12,2) NOT NULL CHECK(total_amount>=0),
  created_at timestamptz NOT NULL,
  reserved_until timestamptz,
  external_token uuid NOT NULL DEFAULT gen_random_uuid()
);
CREATE TABLE hw07.order_items(
  order_id bigint NOT NULL REFERENCES hw07.orders(id) ON DELETE CASCADE,
  line_no int NOT NULL,
  sku text NOT NULL,
  qty int NOT NULL CHECK(qty>0),
  unit_price numeric(12,2) NOT NULL CHECK(unit_price>=0),
  PRIMARY KEY(order_id,line_no)
);
CREATE TABLE hw07.progress(id int PRIMARY KEY, note text NOT NULL);
CREATE TABLE hw07.generated_ids(id bigserial PRIMARY KEY, note text NOT NULL);
CREATE TABLE hw07.lab_state(name text PRIMARY KEY,value text NOT NULL);
CREATE TABLE hw07.events(
  event_id bigint NOT NULL, occurred_at timestamptz NOT NULL,
  tenant_id int NOT NULL, payload jsonb NOT NULL,
  PRIMARY KEY(event_id,occurred_at)
) PARTITION BY RANGE(occurred_at);
CREATE TABLE hw07.events_2026_09 PARTITION OF hw07.events
  FOR VALUES FROM ('2026-09-01 00:00:00+00') TO ('2026-10-01 00:00:00+00');
CREATE TABLE hw07.events_2026_10 PARTITION OF hw07.events
  FOR VALUES FROM ('2026-10-01 00:00:00+00') TO ('2026-11-01 00:00:00+00');
CREATE TABLE hw07.events_2026_11 PARTITION OF hw07.events
  FOR VALUES FROM ('2026-11-01 00:00:00+00') TO ('2026-12-01 00:00:00+00');

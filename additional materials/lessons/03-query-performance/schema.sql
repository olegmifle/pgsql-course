\set ON_ERROR_STOP on
-- Применять один раз в пустой учебной базе. Индексов, включая PK, нет.
BEGIN;
CREATE SCHEMA lab;
CREATE TABLE lab.customers (
  id bigint NOT NULL,
  name text NOT NULL,
  region text
);
CREATE TABLE lab.orders (
  id bigint NOT NULL,
  customer_id bigint NOT NULL,
  status text NOT NULL CHECK (status IN ('paid', 'pending')),
  created_at timestamp NOT NULL,
  total_cents bigint NOT NULL CHECK (total_cents >= 0)
);
CREATE TABLE lab.order_items (
  id bigint NOT NULL,
  order_id bigint NOT NULL,
  sku_id integer NOT NULL,
  qty integer NOT NULL CHECK (qty > 0),
  price_cents bigint NOT NULL CHECK (price_cents >= 0)
);
CREATE TABLE lab.payments (
  id bigint NOT NULL,
  order_id bigint,
  status text NOT NULL CHECK (status IN ('success', 'failed')),
  amount_cents bigint NOT NULL
);
CREATE TABLE lab.events (
  id bigint NOT NULL,
  order_id bigint NOT NULL,
  event_type text NOT NULL,
  occurred_at timestamp NOT NULL,
  payload text NOT NULL
);
COMMENT ON SCHEMA lab IS 'Только лаборатория: уникальность id и связи проверяются seed/sanity; PK/FK опущены ради полного отсутствия индексов';
COMMIT;

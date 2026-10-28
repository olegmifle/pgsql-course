\set ON_ERROR_STOP on
-- Выполните один раз в пустой базе.
CREATE SCHEMA hw05;
CREATE TABLE hw05.orders (
 id bigint PRIMARY KEY,
 store_id integer NOT NULL,
 created_at timestamptz NOT NULL,
 status text NOT NULL CHECK(status IN ('pending','paid')),
 total_amount numeric(12,2) NOT NULL CHECK(total_amount>=0),
 metadata jsonb NOT NULL,
 payload text NOT NULL
) WITH(fillfactor=80);
CREATE INDEX orders_store_idx ON hw05.orders(store_id);
CREATE TABLE hw05.customers(id bigint PRIMARY KEY,email text NOT NULL,name text NOT NULL);
CREATE TABLE hw05.events(id bigint PRIMARY KEY,occurred_at timestamptz NOT NULL,payload text NOT NULL);

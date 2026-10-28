\set ON_ERROR_STOP on
-- Исходная схема. Применять к отдельной пустой базе.
CREATE SCHEMA hw04;

CREATE TABLE hw04.tenants (
    id bigint PRIMARY KEY,
    name text NOT NULL
);
CREATE TABLE hw04.customers (
    id bigint PRIMARY KEY,
    tenant_id bigint NOT NULL REFERENCES hw04.tenants(id),
    email text NOT NULL,
    CONSTRAINT customer_email_in_tenant UNIQUE (tenant_id, email)
);
CREATE TABLE hw04.orders (
    id bigint PRIMARY KEY,
    tenant_id bigint NOT NULL REFERENCES hw04.tenants(id),
    order_no bigint NOT NULL CHECK (order_no > 0),
    customer_id bigint NOT NULL,
    total_cents bigint NOT NULL CHECK (
        total_cents BETWEEN 0 AND 999999999999
    ),
    CONSTRAINT order_customer_exists FOREIGN KEY (customer_id)
        REFERENCES hw04.customers(id)
);
CREATE TABLE hw04.repair_audit (
    order_id bigint PRIMARY KEY REFERENCES hw04.orders(id),
    old_customer_id bigint NOT NULL,
    new_customer_id bigint NOT NULL,
    evidence text NOT NULL,
    repaired_at timestamptz NOT NULL DEFAULT now()
);

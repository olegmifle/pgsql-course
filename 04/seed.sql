\set ON_ERROR_STOP on
BEGIN;
INSERT INTO hw04.tenants VALUES (10, 'Вектор'), (20, 'Маяк');
INSERT INTO hw04.customers VALUES
    (101, 10, 'anna@example.test'),
    (102, 10, 'ilya@example.test'),
    (201, 20, 'boris@example.test');
INSERT INTO hw04.orders VALUES
    (1001, 10, 42, 101, 149990),
    (1002, 20, 42, 201, 50000),
    (1003, 10, 43, 201, 19990);
-- SUP-204: order 1003 остаётся в tenant 10; правильный customer_id = 102.
-- Клиент 101 той же организации к этому заказу отношения не имеет.
COMMIT;

-- Сессия A
BEGIN;
INSERT INTO live04_projection.operations
    (company_id, business_date, request_key, amount_cents)
VALUES (1, '2026-10-27', 'A', 10000)
RETURNING id;

-- Сессия B
BEGIN;
INSERT INTO live04_projection.operations
    (company_id, business_date, request_key, amount_cents)
VALUES (1, '2026-10-27', 'B', 20000)
RETURNING id;
COMMIT;

-- Обработчик: 03_old_batch.sql

-- Сессия A
COMMIT;

-- Сессия A
BEGIN;
INSERT INTO live04_projection.operations
    (company_id, business_date, request_key, amount_cents)
VALUES (1, '2026-10-27', 'A2', 10000)
RETURNING id;

-- Сессия B
BEGIN;
INSERT INTO live04_projection.operations
    (company_id, business_date, request_key, amount_cents)
VALUES (1, '2026-10-27', 'B2', 20000)
RETURNING id;
COMMIT;

-- Обработчик
SELECT live04_projection.apply_batch(2);

-- Сессия A
COMMIT;

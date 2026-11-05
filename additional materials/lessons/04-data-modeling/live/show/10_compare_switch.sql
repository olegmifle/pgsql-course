BEGIN;
DO $$
BEGIN
    IF EXISTS (
        WITH source AS (
            SELECT company_id, business_date, sum(amount_cents) AS total
            FROM live04_projection.operations
            GROUP BY company_id, business_date
        ), target AS (
            SELECT company_id, business_date, total_cents AS total
            FROM live04_projection.turnover_v2 WHERE generation = 2
        )
        SELECT 1 FROM source s FULL JOIN target t
            USING (company_id, business_date)
        WHERE s.total IS DISTINCT FROM t.total
    ) OR EXISTS (
        SELECT 1 FROM live04_projection.operations o
        WHERE NOT EXISTS (
            SELECT 1 FROM live04_projection.projection_applied a
            WHERE a.generation = 2 AND a.operation_id = o.id
        )
    ) THEN
        RAISE EXCEPTION 'Витрина не готова: есть расхождения или пропуски';
    END IF;
END $$;

CREATE OR REPLACE VIEW live04_projection.company_turnover AS
SELECT company_id, business_date, total_cents
FROM live04_projection.turnover_v2 WHERE generation = 2;
COMMIT;

SELECT company_id, business_date, round(total_cents / 100.0, 2) AS report_rub
FROM live04_projection.company_turnover;

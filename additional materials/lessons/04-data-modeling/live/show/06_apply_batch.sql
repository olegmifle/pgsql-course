CREATE FUNCTION live04_projection.apply_batch(p_generation integer)
RETURNS bigint LANGUAGE sql AS $$
    WITH accepted AS (
        INSERT INTO live04_projection.projection_applied
            (generation, operation_id)
        SELECT p_generation, o.id
        FROM live04_projection.operations o
        WHERE NOT EXISTS (
            SELECT 1 FROM live04_projection.projection_applied a
            WHERE a.generation = p_generation AND a.operation_id = o.id
        )
        ORDER BY o.id LIMIT 100
        ON CONFLICT (generation, operation_id) DO NOTHING
        RETURNING operation_id
    ), delta AS (
        SELECT o.company_id, o.business_date, sum(o.amount_cents) AS amount
        FROM live04_projection.operations o
        JOIN accepted a ON a.operation_id = o.id
        GROUP BY o.company_id, o.business_date
    ), updated AS (
        INSERT INTO live04_projection.turnover_v2 AS t
        SELECT p_generation, company_id, business_date, amount FROM delta
        ON CONFLICT (generation, company_id, business_date) DO UPDATE
        SET total_cents = t.total_cents + excluded.total_cents
        RETURNING company_id
    )
    SELECT count(*) FROM accepted;
$$;

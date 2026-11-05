INSERT INTO live04_projection.turnover_v1 AS t
SELECT
    o.company_id, o.business_date,
    sum(o.amount_cents), max(o.id)
FROM live04_projection.operations o
LEFT JOIN live04_projection.turnover_v1 p
    USING (company_id, business_date)
WHERE o.id > coalesce(p.last_id, 0)
GROUP BY o.company_id, o.business_date
ON CONFLICT (company_id, business_date) DO UPDATE
SET total_cents = t.total_cents + excluded.total_cents,
    last_id = excluded.last_id;

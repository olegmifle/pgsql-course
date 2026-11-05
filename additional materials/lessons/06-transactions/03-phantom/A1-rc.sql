BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT array_agg(id ORDER BY id) AS active_ids,count(*) AS active_count
FROM quota_reservations WHERE organization_id=7 AND active;

-- После завершения A: актуально пять строк на обоих уровнях.
SELECT array_agg(id ORDER BY id) AS current_ids,count(*) AS current_count
FROM quota_reservations WHERE organization_id=7 AND active;

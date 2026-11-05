BEGIN;
SELECT live04_projection.apply_batch(2) AS applied;
SELECT round(total_cents / 100.0, 2) AS inside_transaction_rub
FROM live04_projection.turnover_v2 WHERE generation = 2;
ROLLBACK;

SELECT round(total_cents / 100.0, 2) AS after_rollback_rub
FROM live04_projection.turnover_v2 WHERE generation = 2;

SELECT live04_projection.apply_batch(2) AS applied_retry;
SELECT round(total_cents / 100.0, 2) AS after_retry_rub
FROM live04_projection.turnover_v2 WHERE generation = 2;

SELECT live04_projection.apply_batch(2) AS applied_again;

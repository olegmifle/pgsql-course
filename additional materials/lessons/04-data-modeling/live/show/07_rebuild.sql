SELECT live04_projection.apply_batch(2) AS applied;

SELECT
    (SELECT round(sum(amount_cents) / 100.0, 2)
     FROM live04_projection.operations) AS journal_rub,
    (SELECT round(total_cents / 100.0, 2)
     FROM live04_projection.turnover_v1) AS old_rub,
    (SELECT round(total_cents / 100.0, 2)
     FROM live04_projection.turnover_v2 WHERE generation = 2) AS new_rub;

SELECT live04_projection.apply_batch(2) AS applied_again;

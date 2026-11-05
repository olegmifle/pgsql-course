BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT count(*) AS colleagues_on_call FROM on_call WHERE shift_id=1 AND active;

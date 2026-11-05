BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) AS colleagues_on_call FROM on_call WHERE shift_id=1 AND active;

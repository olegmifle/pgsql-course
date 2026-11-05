SELECT doctor_id,active FROM on_call ORDER BY doctor_id;
SELECT count(*) AS on_call, count(*)>=1 AS rule_ok FROM on_call WHERE shift_id=1 AND active;

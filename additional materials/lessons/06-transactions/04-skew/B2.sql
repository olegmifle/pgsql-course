UPDATE on_call SET active=false
WHERE doctor_id=2 AND (SELECT count(*) FROM on_call WHERE shift_id=1 AND active)>1
RETURNING doctor_id;
-- Если получен 40001: ROLLBACK и B-retry.sql; B3 не выполнять.

-- Запускать в B после завершения/очистки неудачной попытки.
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) AS fresh_on_call FROM on_call WHERE shift_id=1 AND active;
UPDATE on_call SET active=false
WHERE doctor_id=2 AND (SELECT count(*) FROM on_call WHERE shift_id=1 AND active)>1
RETURNING doctor_id;
COMMIT;

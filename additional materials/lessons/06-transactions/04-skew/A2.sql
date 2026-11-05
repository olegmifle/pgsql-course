UPDATE on_call SET active=false
WHERE doctor_id=1 AND (SELECT count(*) FROM on_call WHERE shift_id=1 AND active)>1
RETURNING doctor_id;
COMMIT;

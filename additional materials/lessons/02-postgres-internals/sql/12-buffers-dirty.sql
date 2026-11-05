-- сессия изменений, autocommit: the committed UPDATE leaves a dirty data page.
UPDATE underhood.buffer_demo SET counter=counter+1 WHERE id=1;
SELECT * FROM underhood.buffer_state
WHERE relation='underhood.buffer_demo'::regclass;

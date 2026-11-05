-- Дополнительно. Сессия изменений, после шага 50. Этот UPDATE ожидает сессию чтения.
SET lock_timeout='2min';
UPDATE underhood.lock_demo SET counter=counter+10 WHERE id=1;
SELECT * FROM underhood.lock_demo;
RESET lock_timeout;

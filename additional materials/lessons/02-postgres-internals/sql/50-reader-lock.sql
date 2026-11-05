-- Дополнительно. Сессия чтения, после шага 42.
BEGIN;
UPDATE underhood.lock_demo SET counter=counter+1 WHERE id=1;

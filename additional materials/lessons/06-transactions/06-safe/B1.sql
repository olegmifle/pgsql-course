BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE stock SET available=available-1 WHERE sku=42 AND available>=1
RETURNING available;
-- Пока A не завершена, команда ждёт. Не отправлять B2 вперёд.

BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE stock SET available=available-1 WHERE sku=42 AND available>=1
RETURNING available;
-- Продолжать A2 только после одной возвращённой строки.

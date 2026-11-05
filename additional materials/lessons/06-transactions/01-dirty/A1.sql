BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE stock SET available=0 WHERE sku=42;
-- Не делать COMMIT. В A уже 0, B ещё не должна его видеть.

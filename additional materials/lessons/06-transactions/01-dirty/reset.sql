-- A/B: сначала закончить прежние транзакции.
DELETE FROM reservations;
UPDATE stock SET available=1 WHERE sku=42;

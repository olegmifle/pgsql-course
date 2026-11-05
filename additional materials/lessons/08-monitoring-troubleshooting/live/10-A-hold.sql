BEGIN;
UPDATE incident08.orders SET note='maintenance holds row 42' WHERE id=42;
-- A goes idle in transaction and keeps its lock.

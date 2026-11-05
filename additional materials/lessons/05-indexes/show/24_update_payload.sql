BEGIN;
UPDATE orders SET payload = overlay(payload placing 'sync' from 1 for 4)
WHERE id IN (
  SELECT id FROM orders WHERE store_id = 42
  ORDER BY created_at DESC, id DESC LIMIT 20
);
COMMIT;

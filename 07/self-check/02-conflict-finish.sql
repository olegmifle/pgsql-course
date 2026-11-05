\set ON_ERROR_STOP on
BEGIN;
DO $$ BEGIN
  IF NOT EXISTS(SELECT 1 FROM hw07.progress WHERE id=1203) OR
     NOT EXISTS(SELECT 1 FROM hw07.orders WHERE id=1201 AND status='paid') OR
     NOT EXISTS(SELECT 1 FROM hw07.orders WHERE id=1202 AND status='created') THEN
    RAISE EXCEPTION 'The whole source transaction has not been applied yet';
  END IF;
END $$;
UPDATE hw07.orders o SET receipt_token=r.receipt_token
FROM hw07.receipt_repair r WHERE o.id=r.order_id
  AND o.receipt_token IS DISTINCT FROM r.receipt_token;
DELETE FROM hw07.receipt_repair WHERE order_id=1201;
COMMIT;

\set ON_ERROR_STOP on
SET search_path=hw06,public;
DO $$ BEGIN
  IF (SELECT count(*) FROM organizations)<>3
     OR (SELECT count(*) FROM reservations)<>4
     OR (SELECT count(*) FROM debit_operations)<>0
     OR (SELECT count(*) FROM jobs)<>0
     OR (SELECT count(*) FROM wallets WHERE initial_balance=100 AND balance=100)<>3
     OR (SELECT available FROM inventory WHERE sku=100)<>1 THEN
    RAISE EXCEPTION 'Исходное состояние не совпадает: sanity только после первой загрузки';
  END IF;
END $$;
\ir checks.sql
SELECT 'PASS: исходные данные загружены' AS result;

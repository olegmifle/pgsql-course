\set ON_ERROR_STOP on
DO $$ BEGIN
  IF (SELECT count(*) FROM hw08.orders)<>120000 THEN
    RAISE EXCEPTION 'FAIL: orders were lost or duplicated';
  END IF;
  IF (SELECT count(*) FROM hw08.events) NOT IN (10000,20000) THEN
    RAISE EXCEPTION 'FAIL: unexpected event fixture state';
  END IF;
END $$;
SELECT 'PASS: data fixture is consistent; report and diagnostics need review' AS result;
SELECT 'orders' AS relation,count(*) AS rows FROM hw08.orders
UNION ALL SELECT 'events',count(*) FROM hw08.events;

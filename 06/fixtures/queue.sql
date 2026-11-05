\set ON_ERROR_STOP on
-- Однократно в свежей базе: очередь уже оплаченных действий, без зависимости от вашего debit.
BEGIN;
SET LOCAL search_path=hw06,public;
DO $$ BEGIN
 IF EXISTS (SELECT FROM debit_operations WHERE organization_id=9) THEN
   RAISE EXCEPTION 'Для queue.sql нужна организация 9 без прежних списаний';
 END IF;
END $$;
INSERT INTO debit_operations(organization_id,request_key,wallet_id,amount,outcome)
SELECT 9,'queue-'||n,3,10,'pending' FROM generate_series(1,3)n;
INSERT INTO jobs(operation_id,payload)
SELECT id,jsonb_build_object('operation_id',id,'organization_id',9,'amount',amount)
FROM debit_operations WHERE organization_id=9 ORDER BY id;
WITH balances AS (
 SELECT id,100-10*row_number() OVER(ORDER BY id) AS remaining
 FROM debit_operations WHERE organization_id=9
) UPDATE debit_operations d SET outcome='approved',balance_after=b.remaining,job_id=j.id
FROM balances b,jobs j WHERE d.id=b.id AND j.operation_id=d.id;
UPDATE wallets SET balance=70 WHERE id=3;
COMMIT;

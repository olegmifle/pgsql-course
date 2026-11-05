\set ON_ERROR_STOP on
SET search_path=hw06,public;
-- Пустой набор нарушений и PASS означают только корректность текущего состояния.
-- Нужны также расписания: последовательное выполнение не доказывает защиту гонки.
CREATE OR REPLACE VIEW hw06.invariant_violations AS
SELECT 'stock'::text AS rule, i.sku::text AS object_id
FROM inventory i LEFT JOIN reservations r ON r.sku=i.sku AND r.status='active'
GROUP BY i.sku HAVING i.available+coalesce(sum(r.qty),0)<>i.initial_qty
UNION ALL
SELECT 'quota',o.id::text FROM organizations o JOIN reservations r
 ON r.organization_id=o.id AND r.status='active'
GROUP BY o.id HAVING count(*)>o.reservation_limit
UNION ALL
SELECT 'money',w.id::text FROM wallets w LEFT JOIN debit_operations d
 ON d.wallet_id=w.id AND d.outcome='approved'
GROUP BY w.id HAVING w.balance+coalesce(sum(d.amount),0)<>w.initial_balance+
 coalesce((SELECT sum(c.amount) FROM wallet_credits c WHERE c.wallet_id=w.id),0)
UNION ALL
SELECT 'unfinished-operation',d.id::text FROM debit_operations d WHERE d.outcome='pending'
UNION ALL
SELECT 'outbox',d.id::text FROM debit_operations d LEFT JOIN jobs j ON j.operation_id=d.id
GROUP BY d.id HAVING
 (d.outcome='approved' AND (count(j.id)<>1 OR min(j.id) IS DISTINCT FROM d.job_id))
 OR (d.outcome<>'approved' AND count(j.id)<>0);
TABLE invariant_violations;
DO $$ BEGIN
  IF EXISTS (SELECT FROM invariant_violations) THEN
    RAISE EXCEPTION 'FAIL: нарушены бизнес-правила; смотрите таблицу выше';
  END IF;
END $$;
SELECT 'PASS: проверяемые правила текущего состояния' AS result;
-- Добавляйте свои SELECT и проверки отдельно от этого эталона правил.

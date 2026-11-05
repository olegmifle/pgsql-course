\set ON_ERROR_STOP on
CREATE OR REPLACE FUNCTION hw06.debit(p_org bigint,p_key text,p_wallet bigint,p_amount numeric)
RETURNS TABLE(outcome text,balance_after numeric,job_id bigint)
LANGUAGE plpgsql VOLATILE SET search_path=hw06,pg_temp AS $$
DECLARE op bigint; old debit_operations%ROWTYPE; bal numeric; job bigint;
BEGIN
 IF p_amount IS NULL OR p_amount::text IN ('NaN','Infinity','-Infinity')
    OR p_amount<=0 OR p_amount>9999999999.99 OR p_amount<>round(p_amount,2)
    OR p_key IS NULL OR length(p_key) NOT BETWEEN 1 AND 100
    OR NOT EXISTS (SELECT FROM wallets w WHERE w.id=p_wallet AND w.organization_id=p_org) THEN
   RAISE EXCEPTION 'Неверные реквизиты списания' USING ERRCODE='22023';
 END IF;
 INSERT INTO debit_operations(organization_id,request_key,wallet_id,amount,outcome)
 VALUES(p_org,p_key,p_wallet,p_amount,'pending')
 ON CONFLICT (organization_id,request_key) DO NOTHING RETURNING id INTO op;
 IF NOT FOUND THEN
   -- Новая команда с новым снимком RC видит результат победителя после ожидания UNIQUE.
   SELECT d.* INTO STRICT old FROM debit_operations d
   WHERE d.organization_id=p_org AND d.request_key=p_key;
   IF old.wallet_id IS DISTINCT FROM p_wallet OR old.amount IS DISTINCT FROM p_amount THEN
     RAISE EXCEPTION 'Ключ уже связан с другими параметрами' USING ERRCODE='22023';
   END IF;
   IF old.outcome='pending' THEN
     RAISE EXCEPTION 'Обнаружена незавершённая операция' USING ERRCODE='55000';
   END IF;
   RETURN QUERY SELECT old.outcome,old.balance_after,old.job_id;
   RETURN;
 END IF;
 UPDATE wallets w SET balance=w.balance-p_amount
 WHERE w.id=p_wallet AND w.organization_id=p_org AND w.balance>=p_amount
 RETURNING w.balance INTO bal;
 IF NOT FOUND THEN
   SELECT w.balance INTO STRICT bal FROM wallets w WHERE w.id=p_wallet;
   UPDATE debit_operations d SET outcome='declined',balance_after=bal WHERE d.id=op;
   RETURN QUERY SELECT 'declined'::text,bal,NULL::bigint;
   RETURN;
 END IF;
 INSERT INTO jobs(operation_id,payload)
 VALUES(op,jsonb_build_object('operation_id',op,'organization_id',p_org,'amount',p_amount))
 RETURNING id INTO job;
 UPDATE debit_operations d SET outcome='approved',balance_after=bal,job_id=job WHERE d.id=op;
 RETURN QUERY SELECT 'approved'::text,bal,job;
END $$;

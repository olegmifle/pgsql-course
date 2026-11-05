\set ON_ERROR_STOP on
-- Один вариант: общий guard организации и свежий count в Read Committed.
CREATE OR REPLACE FUNCTION hw06.reserve(p_org bigint,p_sku bigint,p_qty integer)
RETURNS bigint LANGUAGE plpgsql VOLATILE SET search_path=hw06,pg_temp AS $$
DECLARE lim integer; active_count bigint; new_id bigint;
BEGIN
 IF current_setting('transaction_isolation')<>'read committed' THEN
   RAISE EXCEPTION 'Эталон reserve требует Read Committed' USING ERRCODE='25001';
 END IF;
 IF p_qty IS NULL OR p_qty<=0 THEN
   RAISE EXCEPTION 'qty должна быть положительной' USING ERRCODE='22023';
 END IF;
 SELECT o.reservation_limit INTO lim FROM organizations o WHERE o.id=p_org FOR NO KEY UPDATE;
 IF NOT FOUND OR NOT EXISTS (SELECT FROM inventory i WHERE i.sku=p_sku) THEN
   RAISE EXCEPTION 'Неизвестная организация/товар' USING ERRCODE='22023';
 END IF;
 -- Отдельная команда ПОСЛЕ получения guard. Не объединять со старым count.
 SELECT count(*) INTO active_count FROM reservations r
 WHERE r.organization_id=p_org AND r.status='active';
 IF active_count>=lim THEN RETURN NULL; END IF;
 UPDATE inventory i SET available=i.available-p_qty WHERE i.sku=p_sku AND i.available>=p_qty;
 IF NOT FOUND THEN RETURN NULL; END IF;
 INSERT INTO reservations(organization_id,sku,qty) VALUES(p_org,p_sku,p_qty) RETURNING id INTO new_id;
 RETURN new_id;
END $$;

CREATE OR REPLACE FUNCTION hw06.cancel(p_res bigint)
RETURNS boolean LANGUAGE plpgsql VOLATILE SET search_path=hw06,pg_temp AS $$
DECLARE org bigint; item reservations%ROWTYPE;
BEGIN
 IF current_setting('transaction_isolation')<>'read committed' THEN
   RAISE EXCEPTION 'Эталон cancel требует Read Committed' USING ERRCODE='25001';
 END IF;
 -- organization_id, sku, qty не меняются после создания резерва.
 SELECT r.organization_id INTO org FROM reservations r WHERE r.id=p_res;
 IF NOT FOUND THEN RETURN false; END IF;
 PERFORM 1 FROM organizations o WHERE o.id=org FOR NO KEY UPDATE;
 UPDATE reservations r SET status='cancelled' WHERE r.id=p_res AND r.status='active'
 RETURNING r.* INTO item;
 IF NOT FOUND THEN RETURN false; END IF;
 UPDATE inventory i SET available=i.available+item.qty WHERE i.sku=item.sku;
 RETURN true;
END $$;

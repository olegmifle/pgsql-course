\set ON_ERROR_STOP on
-- Для L4 источник владеет справочником; в рабочем протоколе нужна его постоянная доставка.
INSERT INTO hw07.tenants VALUES(99,'Новый магазин');
SELECT o.id,o.tenant_id FROM hw07.orders o
LEFT JOIN hw07.tenants t ON t.id=o.tenant_id WHERE t.id IS NULL;

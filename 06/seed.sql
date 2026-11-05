\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path=hw06,public;
INSERT INTO organizations VALUES (7,'Магазин 7',5),(8,'Магазин 8',5),(9,'Магазин 9',5);
INSERT INTO inventory VALUES
 (100,'Последний экземпляр',1,1),
 (200,'Основной товар',20,16),
 (300,'Другой товар',10,10);
INSERT INTO reservations (id,organization_id,sku,qty)
SELECT n,7,200,1 FROM generate_series(1,4) n;
INSERT INTO wallets VALUES (1,7,100,100),(2,8,100,100),(3,9,100,100);
COMMIT;

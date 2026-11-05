-- Новое значение заранее вычислено по прочитанной 1.
UPDATE stock SET available=0 WHERE sku=42;
INSERT INTO reservations VALUES('unsafe-A',42,1);
COMMIT;

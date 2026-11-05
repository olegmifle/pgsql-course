-- Записываем свой ноль, вычисленный ДО COMMIT A.
UPDATE stock SET available=0 WHERE sku=42;
INSERT INTO reservations VALUES('unsafe-B',42,1);
COMMIT;

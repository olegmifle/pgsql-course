\set ON_ERROR_STOP on
-- Одно учебное пополнение кошелька 1 на 80; повтор файла добавит ещё 80.
BEGIN;
UPDATE hw06.wallets SET balance=balance+80 WHERE id=1;
INSERT INTO hw06.wallet_credits(wallet_id,amount) VALUES(1,80);
COMMIT;

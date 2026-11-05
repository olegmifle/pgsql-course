\set ON_ERROR_STOP on
ALTER TABLE hw07.orders ADD COLUMN currency text NOT NULL DEFAULT 'RUB';
-- После применения INSERT 1301 и progress 1302 должны появиться.

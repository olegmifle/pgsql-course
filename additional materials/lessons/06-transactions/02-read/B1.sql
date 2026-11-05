-- В B нет открытой транзакции: UPDATE подтверждается autocommit.
UPDATE stock SET available=0 WHERE sku=42;

SELECT available AS visible_after_rollback FROM stock WHERE sku=42;
COMMIT;

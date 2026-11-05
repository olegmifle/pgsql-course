SELECT s.available,
 coalesce((SELECT sum(r.qty) FROM reservations r WHERE r.sku=s.sku),0) AS reserved,
 s.available+coalesce((SELECT sum(r.qty) FROM reservations r WHERE r.sku=s.sku),0)=1 AS rule_ok
FROM stock s WHERE s.sku=42;

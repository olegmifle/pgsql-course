\set ON_ERROR_STOP on
BEGIN;
-- В опыте writers остановлены; блокировка защищает окно переноса от нового DML.
LOCK TABLE hw07.orders,hw07.order_items IN SHARE ROW EXCLUSIVE MODE;
CREATE TEMP TABLE recovered_orders(row_data jsonb) ON COMMIT DROP;
CREATE TEMP TABLE recovered_items(row_data jsonb) ON COMMIT DROP;
CREATE TEMP TABLE inserted_order_ids(id bigint PRIMARY KEY) ON COMMIT DROP;
\copy recovered_orders FROM '/work/results/recovered-orders.csv' WITH (FORMAT csv,HEADER true)
\copy recovered_items FROM '/work/results/recovered-items.csv' WITH (FORMAT csv,HEADER true)
WITH inserted AS (
  INSERT INTO hw07.orders(id,tenant_id,status,total_amount,created_at,reserved_until,external_token)
  SELECT x.id,x.tenant_id,x.status,x.total_amount,x.created_at,x.reserved_until,x.external_token
  FROM recovered_orders r CROSS JOIN LATERAL jsonb_to_record(r.row_data) AS x(
    id bigint,tenant_id int,status text,total_amount numeric,created_at timestamptz,
    reserved_until timestamptz,external_token uuid)
  WHERE x.tenant_id=42
  ON CONFLICT(id) DO NOTHING
  RETURNING id
)
INSERT INTO inserted_order_ids SELECT id FROM inserted;
SELECT 'inserted_orders' AS result,count(*) FROM inserted_order_ids;
WITH inserted AS (
  INSERT INTO hw07.order_items(order_id,line_no,sku,qty,unit_price)
  SELECT x.order_id,x.line_no,x.sku,x.qty,x.unit_price
  FROM recovered_items r CROSS JOIN LATERAL jsonb_to_record(r.row_data) AS x(
    order_id bigint,line_no int,sku text,qty int,unit_price numeric)
  JOIN inserted_order_ids i ON i.id=x.order_id
  RETURNING order_id
)
SELECT 'inserted_items' AS result,count(*) FROM inserted;
COMMIT;

\set ON_ERROR_STOP on
SET TIME ZONE 'UTC';
BEGIN;
CREATE TEMP TABLE source_rows(row_data jsonb) ON COMMIT DROP;
\copy source_rows FROM '/work/results/source-orders.csv' WITH (FORMAT csv,HEADER true)
WITH s AS (
  SELECT (row_data->>'id')::bigint AS id,row_data AS payload FROM source_rows
), t AS (
  SELECT id,to_jsonb(o)-'receipt_token' AS payload FROM hw07.orders o
)
SELECT coalesce(s.id,t.id) AS id,
  CASE WHEN t.id IS NULL THEN 'missing'
       WHEN s.id IS NULL THEN 'extra' ELSE 'different' END AS difference,
  s.payload AS source_value,t.payload AS subscriber_value
FROM s FULL JOIN t USING(id)
WHERE s.payload IS DISTINCT FROM t.payload
ORDER BY id;
SELECT o.id AS orphan_order,o.tenant_id FROM hw07.orders o
LEFT JOIN hw07.tenants t ON t.id=o.tenant_id WHERE t.id IS NULL;
COMMIT;

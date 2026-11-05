\set ON_ERROR_STOP on
-- Обновите results/source-orders.csv после L1 при остановленных writers.
BEGIN;
CREATE TEMP TABLE source_rows(row_data jsonb) ON COMMIT DROP;
\copy source_rows FROM '/work/results/source-orders.csv' WITH (FORMAT csv,HEADER true)
INSERT INTO hw07.orders(id,tenant_id,status,total_amount,created_at,reserved_until,external_token)
SELECT x.id,x.tenant_id,x.status,x.total_amount,x.created_at,x.reserved_until,x.external_token
FROM source_rows s CROSS JOIN LATERAL jsonb_to_record(s.row_data) AS x(
  id bigint,tenant_id int,status text,total_amount numeric,created_at timestamptz,
  reserved_until timestamptz,external_token uuid)
WHERE x.id=1001
ON CONFLICT(id) DO NOTHING;
COMMIT;

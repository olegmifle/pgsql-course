-- One reference improvement; read only after your own attempt.
-- Ordinary CREATE INDEX is a local fixture action, not a production rollout plan.
CREATE INDEX orders_pending_feed ON hw08.orders
  (tenant_id,created_at DESC,id DESC) WHERE status='pending';
ANALYZE hw08.orders;

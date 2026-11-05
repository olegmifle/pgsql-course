-- The fixture is isolated. A production rollout needs its own DDL/lock budget.
CREATE INDEX orders_pending_feed ON incident08.orders
  (tenant_id,created_at DESC,id DESC) WHERE status='pending';
ANALYZE incident08.orders;

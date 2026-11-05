EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF)
SELECT count(*) FROM events
WHERE date_trunc('month', occurred_at)
      = '2026-10-01 00:00:00+00'::timestamptz;

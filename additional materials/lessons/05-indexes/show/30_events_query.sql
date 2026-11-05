EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM events
WHERE occurred_at >= timestamptz '2026-01-03 00:00:00+00'
  AND occurred_at < timestamptz '2026-01-03 01:00:00+00';

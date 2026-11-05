-- Execute in the SAME O connection after fixtures/window-start/end.sql.
-- Tables: hw08_window_start, hw08_window_end.
-- Keys: dbid, userid, queryid, toplevel. Check stats_since and counters.
-- Calculate delta calls, total_exec_time, shared hits/reads and window mean.
-- Report new, reset/recreated and disappeared entries without false deltas.
-- Metadata: hw08_window_meta_start, hw08_window_meta_end (time/reset/dealloc).
\echo 'STARTER: add your window comparison; do not subtract cumulative means.'

-- Requires both TEMP snapshots in this O session. Only copies are mutated.
-- Each rollback leaves original snapshots unchanged; global pgss is untouched.
BEGIN;
UPDATE hw08_window_end SET stats_since=stats_since+interval '1 second'
WHERE query LIKE 'SELECT id, total_cents FROM hw08.orders%';
\ir window.sql
ROLLBACK;
BEGIN;
INSERT INTO hw08_window_end
SELECT dbid,userid,-9223372036854775807::bigint,toplevel,
       'synthetic new entry: TEMP only',calls,total_exec_time,rows,
       shared_blks_hit,shared_blks_read,stats_since
FROM hw08_window_end
WHERE query LIKE 'SELECT id, total_cents FROM hw08.orders%' LIMIT 1;
\ir window.sql
ROLLBACK;
BEGIN;
DELETE FROM hw08_window_end WHERE query LIKE 'SELECT sum(total_cents)%';
\ir window.sql
ROLLBACK;

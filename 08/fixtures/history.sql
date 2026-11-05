-- Completed export work BEFORE the incident window, a cumulative ranking decoy.
\o /dev/null
SELECT 'SELECT sum(total_cents) AS gross_cents FROM hw08.orders;'
FROM generate_series(1,60)
\gexec
\o
SELECT 'Historical export prepared. This is not the incident workload.' AS fixture;

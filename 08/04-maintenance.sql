-- Your maintenance checks: table stats/size/options, backend xmin,
-- VACUUM progress, replication slots and prepared transactions.
-- Distinguish estimates, wall-clock age and XID age; never label n_dead_tup as bloat%.
-- Filter progress datid before converting relid to local regclass.
\echo 'STARTER: add your maintenance SQL and interpret its limits.'

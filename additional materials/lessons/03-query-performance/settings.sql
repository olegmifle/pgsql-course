\set ON_ERROR_STOP on
-- Общие условия для каждой пары. Не являются способом оптимизации.
SET statement_timeout = '120s';
SET work_mem = '4MB';
SET jit = off;
SET max_parallel_workers_per_gather = 0;
SET TimeZone = 'UTC';
SET application_name = 'hw03';
SELECT version();
SHOW work_mem;
SHOW jit;
SHOW max_parallel_workers_per_gather;
SHOW hash_mem_multiplier;

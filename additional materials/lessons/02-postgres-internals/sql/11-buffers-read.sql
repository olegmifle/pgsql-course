-- сессия изменений. Выполнить дважды. Сравнить shared read и shared hit.
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, SUMMARY OFF)
SELECT sum(octet_length(payload)) FROM underhood.buffer_demo;
SELECT * FROM underhood.buffer_state
WHERE relation='underhood.buffer_demo'::regclass;

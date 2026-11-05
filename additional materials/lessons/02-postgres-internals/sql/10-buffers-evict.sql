-- сессия изменений. Вытеснить учебную relation из shared buffers; кэш ОС не очищается.
CHECKPOINT;
SELECT * FROM pg_buffercache_evict_relation('underhood.buffer_demo'::regclass);
SELECT * FROM underhood.buffer_state
WHERE relation='underhood.buffer_demo'::regclass;

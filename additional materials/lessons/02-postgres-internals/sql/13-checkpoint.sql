-- сессия изменений. Записать dirty pages; зафиксированные значения строк не меняются.
SELECT * FROM underhood.buffer_state
WHERE relation='underhood.buffer_demo'::regclass;
CHECKPOINT;
SELECT * FROM underhood.buffer_state
WHERE relation='underhood.buffer_demo'::regclass;

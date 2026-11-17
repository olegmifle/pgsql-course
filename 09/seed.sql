\set ON_ERROR_STOP on
BEGIN;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM public.readings LIMIT 1) THEN
    RAISE EXCEPTION 'readings уже содержит данные. Загрузчик рассчитан на пустую учебную таблицу.';
  END IF;
END $$;
SELECT date_trunc('minute', clock_timestamp()) - interval '1 day' AS seed_start \gset
INSERT INTO public.readings (sensor_id, measured_at, value, quality)
SELECT (g - 1) % 10000 + 1,
       :'seed_start'::timestamptz + ((g - 1) / 10000) * interval '1 minute',
       round((g % 8000)::numeric / 100 - 20, 2),
       (g % 4)::smallint
FROM generate_series(1, :rows) AS g;
COMMIT;

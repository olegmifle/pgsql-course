\set ON_ERROR_STOP on
SET TIME ZONE 'UTC';
-- Один раз: поздняя доставка 50000 событий с историческим временем.
INSERT INTO hw05.events
SELECT i,timestamptz '2026-01-01 00:00:00+00'+((i-600000)*37%600000)*interval '1 second',repeat(md5(i::text),3)
FROM generate_series(600001,650000) g(i);
ANALYZE hw05.events;
SELECT count(*) AS events_after_delivery FROM hw05.events;

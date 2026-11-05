\set ON_ERROR_STOP on
\ir ../_display.sql
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM live04_projection.operations)
    OR to_regclass('live04_projection.turnover_v2') IS NOT NULL THEN
  RAISE EXCEPTION 'Run core/00_prepare.sql before a new run';
 END IF;
 PERFORM public.dblink_connect('lesson04_a',
  'host=127.0.0.1 dbname=course_lesson04 user=course password=course_local application_name=lesson04-slow-a');
END $$;
\echo ''
\echo 'СЦЕНА 1. Оборот компании Альфа за 27 октября'
\echo 'Журнал хранит операции. Отчёт читает отдельную таблицу итогов.'
\echo 'После обработки всех сохранённых операций сумма отчёта должна сходиться с журналом.'
SELECT company_id AS "Компания",business_date AS "День",
 round(total_cents/100.0,2) AS "Отчёт, RUB",last_id AS "Курсор"
FROM live04_projection.turnover_v1;
\echo 'СЦЕНА 2. Обработчик читает id > last_id, обновляет сумму и курсор одним запросом.'
\if :{?pause_demo}
\prompt 'Enter — продолжить: ' demo_continue
\endif
DO $$ BEGIN PERFORM public.dblink_exec('lesson04_a','BEGIN'); END $$;
SELECT id AS a_id FROM public.dblink('lesson04_a',$remote$
 INSERT INTO live04_projection.operations
 (company_id,business_date,request_key,amount_cents)
 VALUES(1,'2026-10-27','A',10000) RETURNING id
$remote$) AS r(id bigint) \gset
BEGIN;
INSERT INTO live04_projection.operations
 (company_id,business_date,request_key,amount_cents)
 VALUES(1,'2026-10-27','B',20000) RETURNING id AS b_id \gset
COMMIT;
\echo ''
\echo 'СЦЕНА 3. A получила ID' :a_id 'на 100 RUB и остаётся без COMMIT.'
\echo 'B получила ID' :b_id 'на 200 RUB и уже выполнила COMMIT.'
SELECT id AS "Видимый ID",request_key AS "Запрос",round(amount_cents/100.0,2) AS "RUB"
FROM live04_projection.operations ORDER BY id;
\if :{?pause_demo}
\prompt 'Enter — продолжить: ' demo_continue
\endif
\ir ../show/03_old_batch.sql
\echo ''
\echo 'СЦЕНА 4. Первый проход обработчика'
SELECT round(total_cents/100.0,2) AS "Отчёт, RUB",last_id AS "Курсор"
FROM live04_projection.turnover_v1;
\if :{?pause_demo}
\prompt 'Enter — продолжить: ' demo_continue
\endif
DO $$ BEGIN
 PERFORM public.dblink_exec('lesson04_a','COMMIT');
 PERFORM public.dblink_disconnect('lesson04_a');
END $$;
\ir ../show/03_old_batch.sql
\echo ''
\echo 'СЦЕНА 5. A завершилась. Тот же обработчик запущен повторно.'
SELECT id AS "ID",request_key AS "Запрос",round(amount_cents/100.0,2) AS "RUB"
FROM live04_projection.operations ORDER BY id;
SELECT (SELECT round(sum(amount_cents)/100.0,2) FROM live04_projection.operations) AS "Журнал, RUB",
 round(total_cents/100.0,2) AS "Отчёт, RUB",last_id AS "Курсор",
 (SELECT count(*) FROM live04_projection.operations o WHERE o.id>t.last_id) AS "Выше курсора"
FROM live04_projection.turnover_v1 t;
INSERT INTO live04_projection_evidence.observations
SELECT 'source_before',sum(amount_cents) FROM live04_projection.operations
UNION ALL SELECT 'projection_before',total_cents FROM live04_projection.turnover_v1
UNION ALL SELECT 'cursor_before',last_id FROM live04_projection.turnover_v1;
\if :{?pause_demo}
\prompt 'Enter — продолжить: ' demo_continue
\endif
\echo 'Начальные операции и расхождение сохранены.'

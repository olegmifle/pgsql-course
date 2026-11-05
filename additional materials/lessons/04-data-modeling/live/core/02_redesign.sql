\set ON_ERROR_STOP on
\ir ../_display.sql
DO $$ BEGIN
 IF (SELECT result FROM live04_projection_evidence.observations
     WHERE probe='source_before') IS DISTINCT FROM 30000
    OR to_regclass('live04_projection.turnover_v2') IS NOT NULL THEN
  RAISE EXCEPTION 'First run core/01_opening.sql exactly once';
 END IF;
END $$;
\echo ''
\echo 'СЦЕНА 6. Возвращаемся к журналу и неверному отчёту'
SELECT (SELECT round(sum(amount_cents)/100.0,2) FROM live04_projection.operations) AS "Журнал, RUB",
 round(total_cents/100.0,2) AS "Отчёт, RUB",last_id AS "Курсор"
FROM live04_projection.turnover_v1;
\echo 'СЦЕНА 7. Отдельный факт: операция применена в конкретном поколении витрины.'
\if :{?pause_demo}
\prompt 'Enter — продолжить: ' demo_continue
\endif
BEGIN;
\ir ../show/05_new_projection.sql
\ir ../show/06_apply_batch.sql
COMMIT;
\echo 'Новое поколение пусто. Неверный итог старого отчёта не скопирован.'
\if :{?pause_demo}
\prompt 'Enter — продолжить: ' demo_continue
\endif
\echo ''
\echo 'СЦЕНА 8. Восстановление поколения 2 из журнала'
\ir ../show/07_rebuild.sql
SELECT generation AS "Поколение",operation_id AS "Применённый ID"
FROM live04_projection.projection_applied ORDER BY operation_id;
DO $$ BEGIN
 PERFORM public.dblink_connect('lesson04_a',
  'host=127.0.0.1 dbname=course_lesson04 user=course password=course_local application_name=lesson04-slow-a');
 PERFORM public.dblink_exec('lesson04_a','BEGIN');
END $$;
SELECT id AS a_id FROM public.dblink('lesson04_a',$remote$
 INSERT INTO live04_projection.operations
 (company_id,business_date,request_key,amount_cents)
 VALUES(1,'2026-10-27','A2',10000) RETURNING id
$remote$) AS r(id bigint) \gset
BEGIN;
INSERT INTO live04_projection.operations
 (company_id,business_date,request_key,amount_cents)
 VALUES(1,'2026-10-27','B2',20000) RETURNING id AS b_id \gset
COMMIT;
\echo ''
\echo 'СЦЕНА 9. Повтор тех же условий: A2 получила ID' :a_id 'на 100 RUB без COMMIT.'
\echo 'B2 получила ID' :b_id 'на 200 RUB и уже завершилась.'
\if :{?pause_demo}
\prompt 'Enter — продолжить: ' demo_continue
\endif
SELECT live04_projection.apply_batch(2) AS "Применено операций";
SELECT round(total_cents/100.0,2) AS "Новое поколение, RUB"
FROM live04_projection.turnover_v2 WHERE generation=2;
\if :{?pause_demo}
\prompt 'Enter — продолжить: ' demo_continue
\endif
DO $$ BEGIN
 PERFORM public.dblink_exec('lesson04_a','COMMIT');
 PERFORM public.dblink_disconnect('lesson04_a');
END $$;
BEGIN;
SELECT live04_projection.apply_batch(2) AS tentative_applied \gset
SELECT round(total_cents/100.0,2) AS tentative_total
FROM live04_projection.turnover_v2 WHERE generation=2 \gset
ROLLBACK;
SELECT round(total_cents/100.0,2) AS rolled_back_total
FROM live04_projection.turnover_v2 WHERE generation=2 \gset
SELECT count(*) AS rolled_back_receipts
FROM live04_projection.projection_applied WHERE generation=2 \gset
SELECT live04_projection.apply_batch(2) AS retried_applied \gset
SELECT round(total_cents/100.0,2) AS retried_total
FROM live04_projection.turnover_v2 WHERE generation=2 \gset
SELECT live04_projection.apply_batch(2) AS repeated_applied \gset
\echo ''
\echo 'СЦЕНА 10. A2 завершилась: отмена пакета и повтор'
SELECT 'Внутри незавершённого пакета' AS "Состояние",:tentative_total AS "RUB"
UNION ALL SELECT 'После ROLLBACK',:rolled_back_total
UNION ALL SELECT 'После повторной обработки',:retried_total;
SELECT :rolled_back_receipts AS "Отметок после ROLLBACK",
 :retried_applied AS "Применено при повторе",:repeated_applied AS "Применено ещё раз";
INSERT INTO live04_projection_evidence.observations VALUES
 ('cancelled_total',:rolled_back_total*100),('cancelled_receipts',:rolled_back_receipts),
 ('retried_total',:retried_total*100),('repeated_applied',:repeated_applied);
\ir ../show/03_old_batch.sql
SELECT (SELECT round(sum(amount_cents)/100.0,2) FROM live04_projection.operations) AS "Журнал, RUB",
 (SELECT round(total_cents/100.0,2) FROM live04_projection.turnover_v1) AS "Старый отчёт, RUB",
 (SELECT round(total_cents/100.0,2) FROM live04_projection.turnover_v2 WHERE generation=2) AS "Новый, RUB";
\if :{?pause_demo}
\prompt 'Enter — продолжить: ' demo_continue
\endif
\echo ''
\echo 'СЦЕНА 11. Проверка полноты и переключение чтения'
\ir ../show/10_compare_switch.sql
INSERT INTO live04_projection_evidence.observations
SELECT 'source_after',sum(amount_cents) FROM live04_projection.operations
UNION ALL SELECT 'projection_after',total_cents FROM live04_projection.company_turnover;
SELECT 'Начало: журнал / отчёт' AS "Проверка",
 (SELECT round(result/100.0,2) FROM live04_projection_evidence.observations WHERE probe='source_before') AS "Журнал, RUB",
 (SELECT round(result/100.0,2) FROM live04_projection_evidence.observations WHERE probe='projection_before') AS "Отчёт, RUB"
UNION ALL SELECT 'После восстановления и повторного опыта',
 (SELECT round(result/100.0,2) FROM live04_projection_evidence.observations WHERE probe='source_after'),
 (SELECT round(result/100.0,2) FROM live04_projection_evidence.observations WHERE probe='projection_after');

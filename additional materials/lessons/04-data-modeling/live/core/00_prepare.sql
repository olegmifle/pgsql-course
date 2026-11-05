\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_database()<>'course_lesson04' THEN
  RAISE EXCEPTION 'Use the separate course_lesson04 database';
 END IF;
END $$;
CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;
DO $$ BEGIN
 IF 'lesson04_a'=ANY(coalesce(public.dblink_get_connections(),ARRAY[]::text[])) THEN
  PERFORM public.dblink_disconnect('lesson04_a');
 END IF;
END $$;
DROP SCHEMA IF EXISTS live04_projection CASCADE;
DROP SCHEMA IF EXISTS live04_projection_evidence CASCADE;
CREATE SCHEMA live04_projection;
CREATE SCHEMA live04_projection_evidence;
\ir ../show/01_source_schema.sql
\ir ../show/02_old_projection.sql
INSERT INTO live04_projection.companies VALUES(1,'Альфа');
INSERT INTO live04_projection.turnover_v1 VALUES(1,'2026-10-27',0,0);
CREATE TABLE live04_projection_evidence.observations(
 probe text PRIMARY KEY,result bigint NOT NULL
);
\echo 'Журнал и исходная витрина подготовлены.'

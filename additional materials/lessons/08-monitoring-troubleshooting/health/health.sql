\set ON_ERROR_STOP on
\pset pager off
\pset null '(null)'
-- Run in autocommit. Each file has an intentionally short statement timeout.
SET statement_timeout='5s';
SET lock_timeout='500ms';
\echo '=== Context and coverage ==='
\ir 01-context.sql
\echo '=== Current activity ==='
\ir 02-activity.sql
\echo '=== Wait edges ==='
\ir 03-blockers.sql
\echo '=== Cumulative queries: NOT an incident window ==='
\ir 04-statements.sql
\echo '=== Maintenance signals: NOT a bloat measurement ==='
\ir 05-maintenance.sql
\echo '=== Vacuum progress and retention horizons ==='
\ir 06-horizons.sql
\echo '=== Logging coverage ==='
\ir 07-logging.sql

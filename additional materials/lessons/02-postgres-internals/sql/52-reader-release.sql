-- Дополнительно. Сессия чтения, пока сессия изменений ожидает в шаге 51.
SELECT pid,application_name,state,wait_event_type,wait_event,
       pg_blocking_pids(pid) AS blocked_by
FROM pg_stat_activity
WHERE application_name IN ('underhood_reader','underhood_writer')
  AND datname=current_database()
ORDER BY application_name;
COMMIT;

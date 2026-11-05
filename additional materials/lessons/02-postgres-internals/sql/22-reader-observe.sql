-- Сессия чтения. Выполнить до COMMIT сессии изменений и повторить после него.
-- Ввести writer_xid из шага 21; psql запомнит значение в этом подключении.
\if :{?writer_xid}
\else
\prompt 'writer_xid из сессии изменений: ' writer_xid
\endif
SELECT pg_current_snapshot() AS snapshot,
       pg_visible_in_snapshot(:'writer_xid'::xid8,pg_current_snapshot())
         AS writer_completed_before_snapshot;
SELECT id, progress, ctid, xmin, xmax FROM underhood.versions;

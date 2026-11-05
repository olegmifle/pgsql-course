-- сессия чтения, после второго VACUUM в сессии изменений.
SELECT pg_current_snapshot() AS snapshot,
       pg_visible_in_snapshot(:'writer_xid'::xid8,pg_current_snapshot())
         AS writer_completed_before_snapshot;
SELECT id, progress, ctid, xmin, xmax FROM underhood.versions;

\set ON_ERROR_STOP on
\pset pager off
CREATE EXTENSION pg_buffercache;
CREATE EXTENSION pageinspect;
CREATE EXTENSION pg_walinspect;
CREATE SCHEMA underhood;

CREATE TABLE underhood.buffer_demo (
    id integer PRIMARY KEY,
    counter integer NOT NULL DEFAULT 0,
    payload text NOT NULL
) WITH (fillfactor=80, autovacuum_enabled=false);
INSERT INTO underhood.buffer_demo(id, payload)
SELECT g, repeat(md5(g::text), 8) FROM generate_series(1, 30000) AS g;

CREATE TABLE underhood.versions (
    id integer PRIMARY KEY,
    progress integer NOT NULL
) WITH (fillfactor=50, autovacuum_enabled=false);
INSERT INTO underhood.versions VALUES (1,20);

CREATE TABLE underhood.wal_demo (
    id integer PRIMARY KEY,
    counter integer NOT NULL
) WITH (fillfactor=50);
INSERT INTO underhood.wal_demo VALUES (1,0);

CREATE TABLE underhood.lock_demo (
    id integer PRIMARY KEY,
    counter integer NOT NULL
);
INSERT INTO underhood.lock_demo VALUES (1,0);

-- Только основной fork; сверяем базу, tablespace и filenode relation.
CREATE VIEW underhood.buffer_state AS
SELECT c.oid::regclass AS relation,
       count(b.bufferid) AS cached_pages,
       count(b.bufferid) FILTER (WHERE b.isdirty) AS dirty_pages,
       min(b.relblocknumber) AS first_block,
       max(b.relblocknumber) AS last_block
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid=c.relnamespace
JOIN pg_database AS d ON d.datname=current_database()
LEFT JOIN pg_buffercache AS b
  ON b.relfilenode=pg_relation_filenode(c.oid)
 AND b.reldatabase=d.oid
 AND b.reltablespace=CASE WHEN c.reltablespace=0
                         THEN d.dattablespace ELSE c.reltablespace END
 AND b.relforknumber=0
WHERE n.nspname='underhood' AND c.relkind='r'
GROUP BY c.oid;

-- Сырая страница показывает версии без фильтра видимости обычного SELECT.
CREATE VIEW underhood.version_page AS
SELECT format('(0,%s)',lp) AS physical_ctid,
       t_xmin, t_xmax, t_ctid AS next_ctid,
       encode(t_attrs[2],'hex') AS progress_bytes
FROM heap_page_item_attrs(
    get_raw_page('underhood.versions',0),
    'underhood.versions'::regclass
)
WHERE lp_flags=1
ORDER BY lp;

-- Сравниваем одну страницу в shared buffers и в файле таблицы.
-- На этом стенде фоновая запись страниц отложена для воспроизводимого показа.
CREATE VIEW underhood.wal_page_locations AS
SELECT p.location,format('(0,%s)',i.lp) AS physical_ctid,
       i.t_xmin,i.t_xmax,i.t_ctid AS next_ctid,
       encode(i.t_attrs[2],'hex') AS counter_bytes
FROM (
    SELECT 'shared_buffers'::text AS location,
           get_raw_page('underhood.wal_demo',0) AS bytes
    UNION ALL
    SELECT 'relation_file',
           pg_read_binary_file(
               pg_relation_filepath('underhood.wal_demo'::regclass),
               0,current_setting('block_size')::integer)
) AS p
CROSS JOIN LATERAL heap_page_item_attrs(
    p.bytes,'underhood.wal_demo'::regclass
) AS i
WHERE i.lp_flags=1
ORDER BY p.location,i.lp;

VACUUM (ANALYZE, TRUNCATE FALSE) underhood.buffer_demo;
VACUUM (ANALYZE, TRUNCATE FALSE) underhood.versions;
VACUUM (ANALYZE, TRUNCATE FALSE) underhood.wal_demo;
CHECKPOINT;
SELECT version();
SELECT extname, extversion FROM pg_extension
WHERE extname IN ('pg_buffercache','pageinspect','pg_walinspect')
ORDER BY extname;
SHOW fsync;
SHOW synchronous_commit;

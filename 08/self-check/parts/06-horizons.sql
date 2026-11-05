SELECT pid,datname,relid::regclass AS relation,phase,
       heap_blks_total,heap_blks_scanned,heap_blks_vacuumed
FROM pg_stat_progress_vacuum
WHERE datid=(SELECT oid FROM pg_database WHERE datname=current_database());
-- relid is database-local; never cast another database's OID to local regclass.
SELECT pid,datname,application_name,state,backend_xmin,age(backend_xmin) AS xmin_age,
       clock_timestamp()-xact_start AS xact_age
FROM pg_stat_activity WHERE backend_xmin IS NOT NULL ORDER BY age(backend_xmin) DESC;
SELECT slot_name,slot_type,active,xmin,catalog_xmin,restart_lsn,
       wal_status,safe_wal_size
FROM pg_replication_slots;
SELECT gid,prepared,owner,database,transaction,age(transaction) AS xid_age
FROM pg_prepared_xacts;

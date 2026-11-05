-- Необязательное наблюдение в A после A1-ser и до A2.
SELECT DISTINCT mode FROM pg_locks WHERE pid=pg_backend_pid() AND mode='SIReadLock';

-- Demonstration ONLY in this isolated lab; true means signal sent, not lock freed.
SELECT pg_cancel_backend(pid)
FROM pg_stat_activity WHERE application_name='lesson08-A' AND datname=current_database();

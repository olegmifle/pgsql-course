\set ON_ERROR_STOP on
CREATE OR REPLACE FUNCTION hw06.claim(p_worker text,p_lease_seconds integer)
RETURNS TABLE(id bigint,claim_version bigint,payload jsonb)
LANGUAGE plpgsql VOLATILE SET search_path=hw06,pg_temp AS $$
BEGIN
 IF p_worker IS NULL OR length(p_worker)=0 OR p_lease_seconds IS NULL
    OR p_lease_seconds NOT BETWEEN 1 AND 3600 THEN
   RAISE EXCEPTION 'Неверный worker/lease' USING ERRCODE='22023';
 END IF;
 RETURN QUERY WITH candidate AS (
   SELECT j.id FROM jobs j
   WHERE j.status='pending' OR (j.status='running' AND j.lease_until<=clock_timestamp())
   ORDER BY j.id LIMIT 1 FOR UPDATE SKIP LOCKED
 ) UPDATE jobs j SET status='running',worker_id=p_worker,
     claim_version=j.claim_version+1,
     lease_until=clock_timestamp()+make_interval(secs=>p_lease_seconds)
 FROM candidate c WHERE j.id=c.id
 RETURNING j.id,j.claim_version,j.payload;
END $$;

CREATE OR REPLACE FUNCTION hw06.complete(p_job bigint,p_version bigint,p_worker text)
RETURNS boolean LANGUAGE plpgsql VOLATILE SET search_path=hw06,pg_temp AS $$
BEGIN
 UPDATE jobs j SET status='done' WHERE j.id=p_job AND j.status='running'
   AND j.claim_version=p_version AND j.worker_id=p_worker
   AND j.lease_until>clock_timestamp();
 RETURN FOUND;
END $$;

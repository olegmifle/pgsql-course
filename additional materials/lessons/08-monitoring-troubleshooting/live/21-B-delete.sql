DELETE FROM incident08.events WHERE id%2=0;
SELECT count(*) AS current_events FROM incident08.events;

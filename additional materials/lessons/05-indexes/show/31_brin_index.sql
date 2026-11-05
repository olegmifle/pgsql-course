CREATE INDEX events_time_idx
ON events USING brin(occurred_at) WITH (pages_per_range = 32);
SELECT brin_summarize_new_values('live5.events_time_idx'::regclass);

TRUNCATE quota_reservations;
INSERT INTO quota_reservations SELECT n,7,true FROM generate_series(1,4)n;

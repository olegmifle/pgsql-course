\set ON_ERROR_STOP on
\connect course_hw07 course 127.0.0.1 5544
DELETE FROM hw07.orders WHERE id=1001;
\connect course_hw07 course 127.0.0.1 5540
UPDATE hw07.orders SET status='paid' WHERE id=1001;
INSERT INTO hw07.progress VALUES(1101,'after missing UPDATE');

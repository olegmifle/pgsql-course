-- Применить один раз после 01_schema.sql.
BEGIN;

INSERT INTO users(email) VALUES
    ('anna@example.test'),
    ('boris@example.test'),
    ('vera@example.test');

INSERT INTO courses(code, title) VALUES
    ('postgres-dev', 'PostgreSQL для разработчиков'),
    ('sql-basics', 'Основы SQL');

INSERT INTO enrollments(user_id, course_id, amount_cents, status, created_at)
SELECT u.id, c.id, s.amount_cents, s.status, s.created_at
FROM (VALUES
    ('anna@example.test', 'postgres-dev', 150000, 'paid',
        '2026-10-01 12:00:00+00'::timestamptz),
    ('anna@example.test', 'sql-basics', 50000, 'pending',
        '2026-10-01 12:05:00+00'::timestamptz),
    ('boris@example.test', 'postgres-dev', 150000, 'cancelled',
        '2026-10-01 12:10:00+00'::timestamptz)
) AS s(email, course_code, amount_cents, status, created_at)
JOIN users AS u ON u.email = s.email
JOIN courses AS c ON c.code = s.course_code;

COMMIT;

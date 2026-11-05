-- Можно выполнять повторно. Ожидания относятся к данным 02_seed.sql.
SET TIME ZONE 'UTC';

-- Q1: фактическое окружение, значения зависят от способа подключения.
SELECT version(), current_database(), current_user;

-- Q2: users = 3, courses = 2, enrollments = 3.
SELECT 'users' AS table_name, count(*) AS row_count FROM users
UNION ALL
SELECT 'courses', count(*) FROM courses
UNION ALL
SELECT 'enrollments', count(*) FROM enrollments
ORDER BY table_name;

-- Q3: три регистрации с разрешёнными родителями.
SELECT u.email, c.code AS course_code, e.amount_cents, e.status, e.created_at
FROM enrollments AS e
JOIN users AS u ON u.id = e.user_id
JOIN courses AS c ON c.id = e.course_id
ORDER BY u.email, c.code;

-- Q4: ожидается 0, включая отсутствующие обязательные ссылки.
SELECT count(*) AS orphan_enrollments
FROM enrollments AS e
LEFT JOIN users AS u ON u.id = e.user_id
LEFT JOIN courses AS c ON c.id = e.course_id
WHERE u.id IS NULL OR c.id IS NULL;

-- Q5: ожидается 0 строк.
SELECT user_id, course_id, count(*) AS registrations
FROM enrollments
GROUP BY user_id, course_id
HAVING count(*) > 1;

-- Q6: ожидается 0.
SELECT count(*) AS invalid_enrollments
FROM enrollments
WHERE amount_cents IS NULL
   OR amount_cents < 0
   OR status IS NULL
   OR status NOT IN ('pending', 'paid', 'cancelled')
   OR created_at IS NULL;

-- Q7: ожидается anna@example.test.
SELECT u.email
FROM enrollments AS e
JOIN users AS u ON u.id = e.user_id
JOIN courses AS c ON c.id = e.course_id
WHERE c.code = 'postgres-dev' AND e.status = 'paid'
ORDER BY u.email;

-- Q8: ожидается vera@example.test.
SELECT u.email
FROM users AS u
LEFT JOIN enrollments AS e ON e.user_id = u.id
WHERE e.id IS NULL
ORDER BY u.email;

-- Q9: postgres-dev = 2, sql-basics = 1.
SELECT c.code, count(e.id) AS registrations
FROM courses AS c
LEFT JOIN enrollments AS e ON e.course_id = c.id
GROUP BY c.id, c.code
ORDER BY c.code;

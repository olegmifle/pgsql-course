-- Каждая команда должна завершиться ожидаемой ошибкой.
-- Выполнять отдельно в autocommit: psql с ON_ERROR_STOP=0.
-- Родительские строки должны быть загружены через 02_seed.sql.

-- 1. Повтор пары: UNIQUE, SQLSTATE 23505.
INSERT INTO enrollments(user_id, course_id, amount_cents, status)
SELECT u.id, c.id, 150000, 'paid'
FROM users AS u
CROSS JOIN courses AS c
WHERE u.email = 'anna@example.test' AND c.code = 'postgres-dev';

-- 2. Отсутствующий пользователь: FOREIGN KEY, SQLSTATE 23503.
INSERT INTO enrollments(user_id, course_id, amount_cents, status)
SELECT -1, c.id, 150000, 'pending'
FROM courses AS c
WHERE c.code = 'postgres-dev';

-- 3. Отрицательная сумма для новой пары: CHECK, SQLSTATE 23514.
INSERT INTO enrollments(user_id, course_id, amount_cents, status)
SELECT u.id, c.id, -100, 'paid'
FROM users AS u
CROSS JOIN courses AS c
WHERE u.email = 'vera@example.test' AND c.code = 'postgres-dev';

-- 4. Неизвестная сумма: NOT NULL, SQLSTATE 23502.
INSERT INTO enrollments(user_id, course_id, amount_cents, status)
SELECT u.id, c.id, NULL, 'pending'
FROM users AS u
CROSS JOIN courses AS c
WHERE u.email = 'vera@example.test' AND c.code = 'sql-basics';

-- 5. Статус вне словаря: CHECK, SQLSTATE 23514.
INSERT INTO enrollments(user_id, course_id, amount_cents, status)
SELECT u.id, c.id, 50000, 'unknown'
FROM users AS u
CROSS JOIN courses AS c
WHERE u.email = 'vera@example.test' AND c.code = 'sql-basics';

-- 6. Повтор email: UNIQUE, SQLSTATE 23505.
INSERT INTO users(email) VALUES ('anna@example.test');

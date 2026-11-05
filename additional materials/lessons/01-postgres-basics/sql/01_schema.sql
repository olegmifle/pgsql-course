-- Стартовая миграция. Применить один раз в пустой учебной базе.
BEGIN;

CREATE TABLE users (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email text NOT NULL,
    CONSTRAINT users_email_unique UNIQUE (email)
);

CREATE TABLE courses (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code text NOT NULL,
    title text NOT NULL,
    CONSTRAINT courses_code_unique UNIQUE (code)
);

CREATE TABLE enrollments (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint NOT NULL,
    course_id bigint NOT NULL,
    amount_cents bigint NOT NULL,
    status text NOT NULL DEFAULT 'pending',
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT enrollments_user_fk FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT enrollments_course_fk FOREIGN KEY (course_id) REFERENCES courses(id),
    CONSTRAINT enrollments_user_course_unique UNIQUE (user_id, course_id),
    CONSTRAINT enrollments_amount_nonnegative CHECK (amount_cents >= 0),
    CONSTRAINT enrollments_status_allowed
        CHECK (status IN ('pending', 'paid', 'cancelled'))
);

COMMIT;

# Управляемые сценарии

Все shell-команды выполняются из корня пакета. Окна A/B/O подключены к **одной выбранной БД**, init загружен по [README](README.md). Нужен ещё один shell для логов. Это последовательный маршрут; перед переходом к следующему опыту завершайте старые A/B через COMMIT или ROLLBACK.

До каждого опыта запишите прогноз, альтернативное объяснение и ожидаемый сигнал. После команды сначала сохраните факт, затем формулируйте диагноз.

## 1. Окно работы ленты

Сначала сохраните накопленный топ своим 01-health.sql: найдите историю экспорта и спросите, доказывает ли она причину текущего симптома.

| Шаг | Окно | Действие |
| --- | --- | --- |
| 1 | O | `\i /work/fixtures/window-start.sql` |
| 2 | B | `\i /work/fixtures/workload.sql` |
| 3 | O | `\i /work/fixtures/window-end.sql` |
| 4 | O | `\i /work/02-window.sql` — ваш анализ |

Workload выполняет 12 вызовов ленты и 80 точечных чтений. Экспорт во время окна не запускается. Время зависит от машины. Снимки и таблицы hw08_window_meta_start/end принадлежат **одному подключению O**: не открывайте для анализа новый psql. Метаданные показывают время, stats_reset/dealloc; сравните их и качество отдельных записей.

Дальше сохранить результат и план исходной ленты из shell:

```sh
mkdir -p results
docker compose exec -T postgres psql -X -U course -d course_hw08 -f /work/queries.sql > results/feed-before.txt
docker compose exec -T postgres psql -X -U course -d course_hw08 -f /work/plan.sql > results/plan-before.txt
```

Выберите одно исправление, запишите improve.sql. На маленьком учебном стенде можно выполнить DDL напрямую; для рабочего сервиса требуется отдельный план построения/блокировок.

```sh
docker compose exec -T postgres psql -X -U course -d course_hw08 -v ON_ERROR_STOP=1 -f /work/improve.sql
docker compose exec -T postgres psql -X -U course -d course_hw08 -f /work/queries.sql > results/feed-after.txt
diff -u results/feed-before.txt results/feed-after.txt
```

Повторите запуск plan.sql из предыдущей команды, сохранив в plan-after.txt. Повторите шаги 1–4 с **новым началом окна**, сохраните новый результат. Не сравнивайте новое выполнение со старым общим mean. Индекс на повторе уже существует; improve.sql вторично не запускается.

Для сохранения вывода TEMP-анализа используйте [инструкцию results](results/README.md). Эталон [self-check/window.sql](self-check/window.sql) смотреть после своего решения.

## 2. Блокировка и эффект cancel

| Шаг | Окно | Команда | Что зафиксировать |
| --- | --- | --- | --- |
| 1 | A | `\i /work/fixtures/lock-A.sql` | Транзакция остаётся открытой |
| 2 | B | `\i /work/fixtures/lock-B.sql` | UPDATE ещё не вернулся |
| 3 | O | `\i /work/03-locks.sql` | Жертва, блокер, states, ages, identities |
| 4 | O | `\i /work/fixtures/cancel-A.sql` | Ответ на учебный сигнал |
| 5 | O | `\i /work/03-locks.sql` | Эффект сигнала на ожидание |
| 6 | A | `ROLLBACK;` | Владелец завершил попытку |
| 7 | B | После возврата UPDATE: `COMMIT;` | Операция закончена |
| 8 | O | `\i /work/03-locks.sql` | Повторная проверка |

Не отправляйте COMMIT в ожидающее окно B заранее. Cancel-A ограничен учебной базой и именем A; не запускайте такие сигналы по чужим подключениям. Сделайте паузу хотя бы до появления log_lock_waits (порог в стенде 200ms), если хотите сохранить сообщение `still waiting`.

## 3. Дедлок и историческое событие

Прежде чем продолжить, **обе предыдущие транзакции завершены**.

| Шаг | Окно | Команда |
| --- | --- | --- |
| 1 | A | `\i /work/fixtures/deadlock-A1.sql` |
| 2 | B | `\i /work/fixtures/deadlock-B1.sql` |
| 3 | A | `\i /work/fixtures/deadlock-A2.sql` — ждёт |
| 4 | B | `\i /work/fixtures/deadlock-B2.sql` — замыкает цикл |
| 5 | A и B | Дождаться разрешения и выполнить `ROLLBACK;` в обоих |

Сохранить SQLSTATE и лог, жертву заранее не фиксировать:

```sh
docker compose logs --no-color --since 10m postgres > results/deadlock.log
```

В логе коррелируйте db, PID, session, app, SQLSTATE и время. Постройте цикл по двум ожидаемым транзакциям, проверьте порядок команд. В activity после отказа часть события уже может отсутствовать.

## 4. Снимок и обслуживание

| Шаг | Окно | Команда | Свидетельство |
| --- | --- | --- | --- |
| 1 | A | `\i /work/fixtures/reader-A.sql` | BEGIN RR и первый count фиксируют снимок |
| 2 | B | `\i /work/fixtures/delete-B.sql` | DELETE autocommit и свежий count |
| 3 | A | `SELECT count(*) FROM hw08.events;` | Прежний снимок |
| 4 | O | `\i /work/fixtures/vacuum.sql` | Первый VERBOSE |
| 5 | O | `\i /work/04-maintenance.sql` | Горизонт, оценочные счётчики и размер |
| 6 | A | `COMMIT;` | Освобождение снимка |
| 7 | O | Повторить vacuum.sql и 04-maintenance.sql | Второй VERBOSE и состояние |

VACUUM выполняется вне BEGIN. TRUNCATE FALSE отключает обрезание хвоста для управляемого сравнения размера. VACUUM VERBOSE пишет сообщения в stderr: для сохранения из shell нужен `2>&1`, подробнее в results/README.md. У короткого VACUUM может не оказаться строки в снимке progress — это не отказ сценария.

Для чистого повторения создайте свежую БД: повторный DELETE уже удалённых строк не воспроизводит исходное условие. Не заменяйте состояние таблицы скрытым reset во время отчёта.

## 5. Общий отчёт

Соберите свой 01-health.sql и выполните его ролью hw08_monitor, как в README. Вызовите checks.sql от course после завершения A/B. Подготовьте report.md и три правила алертов. Для проверки всего маршрута готовым SQL воспользуйтесь [self-check](self-check/README.md) в другой свежей БД.

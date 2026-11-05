# Пакет домашнего задания 8

**DB health report: три инцидента сервиса заказов.** После настройки среды ориентир — 2–3 часа для middle, 1,5–2 часа для senior; дополнительная ветка 20–40 минут. Сначала прочитайте [условие](homework.md).

Нужен Docker с Compose v2. PostgreSQL и psql находятся в контейнере. Пакет работает отдельно от материалов курса; Python, локальный PostgreSQL и внешний датасет не нужны. Папку можно целиком положить в Git. [Ключ](answer-key.md) и [эталоны](self-check/README.md) открывайте после своей попытки.

## Состав

| Файлы | Назначение |
| --- | --- |
| [homework.md](homework.md), [scenarios.md](scenarios.md) | Условие, последовательность A/B/O и свидетельства |
| [compose.yaml](compose.yaml), [schema.sql](schema.sql), [seed.sql](seed.sql), [sanity.sql](sanity.sql) | Отдельный стенд и готовые данные |
| [queries.sql](queries.sql), [plan.sql](plan.sql) | Исходная лента заказов и её EXPLAIN для первого инцидента |
| [01-health.sql](01-health.sql), [02-window.sql](02-window.sql), [03-locks.sql](03-locks.sql), [04-maintenance.sql](04-maintenance.sql) | Ваши диагностические SQL |
| [sessions/](sessions), [fixtures/](fixtures) | Настройки окон, нагрузка, снимки и управляемые инциденты |
| [report-template.md](report-template.md), [checks.sql](checks.sql) | Отчёт и проверка технического состояния данных |
| [answer-key.md](answer-key.md), [self-check/](self-check/README.md) | Разбор и пример диагностических запросов |
| [results/README.md](results/README.md), [images/README.md](images/README.md) | Сохранение свидетельств и работа с образом Docker |

## Запуск

**Все shell-команды выполняются из корня этой папки**, рядом с compose.yaml:

```sh
docker compose up -d --wait
docker compose exec -T postgres psql -X -U course -d course_hw08 -v ON_ERROR_STOP=1 -f /work/schema.sql -f /work/seed.sql -f /work/sanity.sql
```

PostgreSQL 18.4-alpine, проект pgcourse-hw08, база course_hw08, схема hw08, пользователь course, учебный пароль course_local. Порт хоста не публикуется. Файлы доступны внутри контейнера в /work только для чтения; редактируйте их на компьютере. Данные сохраняются в именованном volume.

В orders 120 000 строк. Арендатор 1 крупный — 60 000 строк; остальные существенно меньше. В events 20 000 строк. Перед инцидентом подготовлена история завершённых экспортов. Это накопленная работа, а не текущая нагрузка. Только у учебной events отключён autovacuum для воспроизводимости третьего опыта; остальные таблицы работают в обычном режиме.

Schema и seed запускаются **один раз в свежей БД**. Повтор отклоняется, существующая работа не стирается. Если схема создана, но seed ещё не выполнялся, запускайте только seed и sanity. Если нужен чистый повтор после изменения данных, создайте другую БД:

```sh
docker compose exec -T postgres createdb -U course hw08_repeat
docker compose exec -T postgres psql -X -U course -d hw08_repeat -v ON_ERROR_STOP=1 -f /work/schema.sql -f /work/seed.sql -f /work/sanity.sql
```

Далее замените имя БД во **всех** своих подключениях и shell-командах. Повторное createdb с занятым именем завершится ошибкой. Перезапуск контейнера данные не очищает.

Если Docker работает через явный контекст, вставляйте его в каждую команду: `docker --context ИМЯ compose ...`. Например, на авторском компьютере используется colima-pgcourse06-live; это имя среды автора, не зависимость пакета. Глобальный контекст менять не требуется.

## A, B и наблюдатель O

Откройте **три терминала** к одной выбранной базе:

```sh
docker compose exec postgres psql -X -U course -d course_hw08
```

В первом: `\i /work/sessions/A.sql`, во втором: `\i /work/sessions/B.sql`, в третьем: `\i /work/sessions/O.sql`. Приглашения отличаются. `*` означает открытую транзакцию, `!` — ошибку внутри неё. После ожидаемой ошибки сделайте ROLLBACK. Пейджер отключён.

A/B имеют lock_timeout 5 минут, statement_timeout 6 минут и idle-in-transaction timeout 15 минут для ручных переключений. O — диагностические 15/30 секунд. Это учебные бюджеты. Если зависшая команда получила timeout, завершите обе попытки через ROLLBACK и повторите соответствующий сценарий.

O использует course, потому что сохраняет TEMP-снимки и выполняет учебные действия. Итоговый health check проверяется отдельно от имени **hw08_monitor**: эта роль имеет pg_monitor и read-only по умолчанию, но не владеет таблицами и не получила pg_signal_backend. Метрики и тексты других запросов доступны этой роли как привилегированные сведения.

## Работа и сдача

1. Заполните собственные SQL-заготовки. Они содержат только задания: успешная загрузка пустого файла не является решением.
2. Выполните [сценарии](scenarios.md), сохраняйте фактические результаты и решения до чтения ключа.
3. Скопируйте report-template.md в report.md, сформулируйте диагнозы, ограничения и три алерта.
4. После собственной попытки сравните с [эталоном](self-check/README.md).

Для итогового отчёта:

```sh
mkdir -p results
docker compose exec -T postgres psql -X -U hw08_monitor -d course_hw08 -v ON_ERROR_STOP=1 -f /work/01-health.sql > results/health.txt
docker compose exec -T postgres psql -X -U course -d course_hw08 -v ON_ERROR_STOP=1 -f /work/checks.sql > results/final-state.txt
```

Первый запрос выполняйте, когда вы уже добавили диагностику. `checks.sql` проверяет только техническое состояние данных. Он не оценивает диагноз, SQL студента, алерты или достаточность доказательств.

Часть свидетельств надо сохранять **во время** инцидента: после освобождения locks/снимка их уже не будет в текущих представлениях. Как это сделать — в [results/README.md](results/README.md).

Папка results исключена из Git. Выбранные свидетельства приложите отдельно либо добавьте через `git add -f results/ИМЯ`. Собственные SQL, report.md и improve.sql отслеживаются обычным образом. В пакет не входят PDF, ZIP и образы Docker.

Завершить работу с сохранением данных:

```sh
docker compose down
```

## Первичные источники

[pg_stat_statements](https://www.postgresql.org/docs/18/pgstatstatements.html), [activity и статистика](https://www.postgresql.org/docs/18/monitoring-stats.html), [обслуживание](https://www.postgresql.org/docs/18/routine-vacuuming.html). SQL пакета ориентирован на PostgreSQL 18; набор полей проверяйте при переносе на другую версию.

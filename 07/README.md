# Пакет домашнего задания 7

**Гарантии чтения, логическая проекция и выборочное восстановление заказов.** Начните с [условия](homework.md). Основная часть — три блока; ориентир 6–8 часов для middle и 3–5 часов для senior. Дополнительные задачи отмечены отдельно.

## Состав

| Файл | Назначение |
| --- | --- |
| [Условие](homework.md) | Контракты, исходные состояния, сдача и оценка |
| [compose.yaml](compose.yaml), [lab/boot.sh](lab/boot.sh) | Готовые primary, r1, r2, subscriber и физическая копия |
| [schema.sql](schema.sql), [seed.sql](seed.sql) | Модель и небольшие данные; запускаются автоматически |
| [scenarios.md](scenarios.md), [observer.sql](observer.sql) | Порядок действий и наблюдение ожиданий |
| [01-reads.sql](01-reads.sql), [02-reconcile.sql](02-reconcile.sql), [03-repair.sql](03-repair.sql) | Ваш SQL |
| [Политика чтения](01-read-policy.md), [исправление проекции](02-repair-policy.md), [план восстановления](03-recovery-plan.md) | Ваши протоколы приложения |
| [checks.sql](checks.sql), [отчёт](report-template.md) | Проверки и выбранные свидетельства |
| [Ключ](answer-key.md), [self-check](self-check/README.md) | Разбор после собственной попытки |
| [Образ Docker](images/README.md) | Перенос без интернета |

## Запуск

Нужен Docker с Compose v2. PostgreSQL, psql, Python и PgBouncer на компьютере не требуются. Все команды ниже выполняются из корня **готового пакета**, где лежит compose.yaml:

```sh
docker compose up -d --wait --wait-timeout 180
docker compose exec -T lab sh /work/lab/control.sh status
```

Один контейнер postgres:18.4-alpine содержит четыре отдельных кластера; при PITR запускается пятый. Желательно выделить Docker не меньше 2 ГБ памяти и около 2 ГБ диска для опыта. Порт компьютера не публикуется. Подключения идут внутри контейнера через 127.0.0.1 с учебным суперпользователем course и trust-аутентификацией; база course_hw07. Это изолированная учебная среда, права приложения в рабочей системе нужно проектировать отдельно.

| Узел | Внутренний порт | Роль |
| --- | --- | --- |
| primary | 5540 | Запись и publisher |
| r1 | 5541 | Физический hot standby |
| r2 | 5543 | Второй физический hot standby |
| subscriber | 5544 | Самостоятельная логическая модель чтения |
| restored | 5545 | Отдельная копия на цели PITR, после recover |

Данные находятся в именованном Docker volume. Файлы пакета доступны в /work только для чтения. Редактируйте SQL на компьютере. Первый запуск создаёт данные, подписку и проверенную физическую копию автоматически. Schema/seed вручную не запускайте: повтор не является сбросом.

## Независимые попытки

Для каждого основного блока используйте свежий Compose project. Например, для блока 1 в текущем терминале:

```sh
export COMPOSE_PROJECT_NAME=hw07-reads
docker compose up -d --wait --wait-timeout 180
```

Во всех дополнительных терминалах задайте **то же** COMPOSE_PROJECT_NAME. Оно выбирает контейнер и volume для каждого docker compose. Для блока 2 после down выберите hw07-logical, для блока 3 — hw07-recovery. Используйте новые имена для повторных чистых попыток. Перезапуск существующего project сохраняет данные и настройки; не запускайте те же фикстуры повторно.

Остановить текущую среду:

```sh
docker compose down
```

Volume сохраняется. Обычный restart/down не возвращает исходные данные. Если при первом запуске случился сбой подготовки, смотрите `docker compose logs lab`, затем продолжайте после исправления причины или начните новый project. Скрипты не удаляют прежнюю работу автоматически.

## Работа с SQL

Интерактивное подключение к выбранному узлу:

```sh
docker compose exec lab sh /work/lab/control.sh psql primary
```

Замените primary на r1, r2, subscriber или restored. В psql задайте имя сессии и удобный вывод:

```sql
SET application_name='hw07-A';
\pset pager off
\set VERBOSITY verbose
\set ON_ERROR_STOP off
SET statement_timeout='5min';
```

Имена B/observer задаются аналогично. Большой timeout здесь нужен для ручных расписаний; это не бюджет запросов приложения. После ожидаемой ошибки внутри BEGIN выполните ROLLBACK.

Применить собственный файл к subscriber:

```sh
docker compose exec -T lab sh /work/lab/control.sh psql subscriber -f /work/02-reconcile.sql
```

Файлы-заготовки пока содержат только комментарии. Успешная загрузка пустого файла не означает выполненное задание.

## Управление состоянием

```sh
docker compose exec -T lab sh /work/lab/control.sh pause r2
docker compose exec -T lab sh /work/lab/control.sh resume r2
docker compose exec -T lab sh /work/lab/control.sh sync any1
docker compose exec -T lab sh /work/lab/control.sh sync any2
docker compose exec -T lab sh /work/lab/control.sh sync async
```

Sync меняет только synchronous_standby_names. Для нужной транзакции задавайте synchronous_commit явно. После блока 1 верните обе реплики в replay и sync async. Для наблюдения primary: `\i /work/observer.sql`. Журнал subscriber: `docker compose exec -T lab sh /work/lab/control.sh log subscriber`.

## Выгрузка для сверки и переноса

Snapshot выдаёт CSV с одной колонкой JSONB: все исходные поля строки сохраняются, включая добавленные позднее. Команды не меняют данные. Сохраняйте файлы на компьютере:

```sh
mkdir -p results
docker compose exec -T lab sh /work/lab/control.sh snapshot primary orders > results/source-orders.csv
docker compose exec -T lab sh /work/lab/control.sh snapshot restored orders > results/recovered-orders.csv
docker compose exec -T lab sh /work/lab/control.sh snapshot restored items > results/recovered-items.csv
```

Для импорта во временную таблицу в psql используйте \copy с `/work/results/имя.csv`. Файлы уже видны контейнеру через read-only mount; PostgreSQL пишет только в свои данные. Договоритесь об остановке соответствующих writers на время актуального снимка и исправления. Поля времени выгружаются в UTC.

Скопируйте report-template.md в report.md, сохраните выбранные выводы в results. Папка результатов исключена из Git; нужные свидетельства приложите отдельно или добавьте выборочно через git add -f. SQL и три файла политик должны отслеживаться обычным образом. PDF, ZIP, архив образа и Docker volume в Git-папку не входят.

# Пакет домашнего задания 4

**Проектирование модели данных.** Начните с [homework.md](homework.md). Схема и данные готовы; собственные решения записывайте в заготовки SQL. [Ключ](answer-key.md) и [self-check](self-check/README.md) открывайте после своей попытки.

Папку можно целиком разместить в Git или передать студентам. Все ссылки и команды относятся к файлам внутри пакета. Для работы достаточно Docker с Compose: psql уже есть в контейнере. Python и отдельный SQL-клиент не требуются.

## Состав пакета

| Файл или папка | Назначение |
| --- | --- |
| [homework.md](homework.md) | Кейс и задания |
| [compose.yaml](compose.yaml) | Отдельный стенд PostgreSQL 18.4 |
| [schema.sql](schema.sql), [seed.sql](seed.sql) | Готовая исходная схема и три заказа |
| [sanity.sql](sanity.sql) | Просмотр исходных данных |
| [queries.sql](queries.sql), [checks.sql](checks.sql) | Место для диагностики и своих проб |
| [01-protect.sql](01-protect.sql), [02-repair.sql](02-repair.sql) | Добавление ограничений и исправление заказа |
| [03-expand.sql](03-expand.sql), [04-cutover.sql](04-cutover.sql) | Переход на сумму в рублях |
| [05-rollback.sql](05-rollback.sql) | Заготовка возврата старой версии приложения |
| [fixtures/audit-error-on.sql](fixtures/audit-error-on.sql), [audit-error-off.sql](fixtures/audit-error-off.sql) | Готовая ошибка записи аудита и её отключение |
| [prepare-mixed.sql](prepare-mixed.sql) | Сценарий одновременной работы старой и переходной версий |
| [report-template.md](report-template.md) | Краткий отчёт и план выпуска |
| [answer-key.md](answer-key.md), [self-check/](self-check/README.md) | Решения с пояснениями и SQL для самопроверки |
| [images/README.md](images/README.md) | Получение образа, подготовка без интернета |

В Git входят Markdown, SQL, compose.yaml и .gitignore. PDF, архивы, образ Docker и материалы самой лекции в пакет не включены. Собственные SQL и report.md можно хранить рядом с исходниками: .gitignore их не исключает.

## Подключение

Откройте терминал в этой папке, рядом с compose.yaml:

```sh
docker compose up -d --wait
docker compose exec -T postgres psql -X -U course -d course_hw04 -c 'SELECT version(), current_database(), current_user;'
```

Пользователь — course, база — course_hw04. Пароль внутри локального стенда — course_local. Подключение выполняется в контейнере, публикация порта на компьютере не нужна.

## Схема и данные

Примените файлы один раз к пустой базе:

```sh
docker compose exec -T postgres psql -X -U course -d course_hw04 -v ON_ERROR_STOP=1 -f /work/schema.sql -f /work/seed.sql -f /work/sanity.sql
```

Появятся 2 организации, 3 клиента и 3 заказа, журнал исправлений пуст. Одна связь заказа с клиентом намеренно неверна. Папка пакета доступна в контейнере как /work для чтения; файлы редактируйте на компьютере.

## Свои решения

Заполните queries.sql и 01-protect.sql, затем добавьте ограничения:

```sh
docker compose exec -T postgres psql -X -U course -d course_hw04 -v ON_ERROR_STOP=1 -f /work/01-protect.sql
```

Заполните 02-repair.sql. Перед первым успешным исправлением включите готовую ошибку записи аудита и запустите свой файл:

```sh
docker compose exec -T postgres psql -X -U course -d course_hw04 -v ON_ERROR_STOP=1 -f /work/fixtures/audit-error-on.sql
docker compose exec -T postgres psql -X -U course -d course_hw04 -v ON_ERROR_STOP=1 -f /work/02-repair.sql
```

При записи аудита ожидается ошибка SQL; psql завершится с ненулевым кодом. В новом подключении проверьте, что осталось в заказе и аудите. Затем отключите ошибку, выполните исправление и запустите файл ещё раз после успешного завершения:

```sh
docker compose exec -T postgres psql -X -U course -d course_hw04 -v ON_ERROR_STOP=1 -f /work/fixtures/audit-error-off.sql
docker compose exec -T postgres psql -X -U course -d course_hw04 -v ON_ERROR_STOP=1 -f /work/02-repair.sql
docker compose exec -T postgres psql -X -U course -d course_hw04 -v ON_ERROR_STOP=1 -f /work/02-repair.sql
```

Заполните и выполните 03-expand.sql:

```sh
docker compose exec -T postgres psql -X -U course -d course_hw04 -v ON_ERROR_STOP=1 -f /work/03-expand.sql
```

Запишите в queries.sql и отчёте, как планируете читать и переносить суммы. Сохраните этот вариант перед запуском сценария смешанных версий:

```sh
docker compose exec -T postgres psql -X -U course -d course_hw04 -v ON_ERROR_STOP=1 -f /work/prepare-mixed.sql
```

Проверьте суммы после сценария и подготовьте план переключения. Выполните 04-cutover.sql и проверьте, какие записи теперь допускает схема. Затем верните старую версию через 05-rollback.sql:

```sh
docker compose exec -T postgres psql -X -U course -d course_hw04 -v ON_ERROR_STOP=1 -f /work/04-cutover.sql
docker compose exec -T postgres psql -X -U course -d course_hw04 -v ON_ERROR_STOP=1 -f /work/05-rollback.sql
```

Эти две команды выполняйте отдельно: после 04 проверьте состояние схемы и данных, затем переходите к 05. Файлы 01/03/04/05 применяются один раз и в указанном порядке. Файл 02 нужно запустить повторно после COMMIT, чтобы проверить, что заказ и аудит не изменятся. Диагностику и свои пробы выполняйте через интерактивный psql:

```sh
docker compose exec postgres psql -X -U course -d course_hw04
```

Скопируйте нужный запрос из queries.sql или checks.sql в psql. Пробы с ожидаемыми ошибками выполняйте по одной, между BEGIN и ROLLBACK. После ошибки сначала выполните ROLLBACK. Не запускайте весь checks.sql через psql -f: ON_ERROR_STOP остановит файл на первой такой ошибке. Выход из psql — `\q`.

Скопируйте report-template.md в report.md и заполните его. Передайте отчёт и заполненные queries.sql, checks.sql, 01-protect.sql … 05-rollback.sql.

## Повторный прогон и самопроверка

Если нужно заново применить изменённые стадии, создайте другую пустую базу:

```sh
docker compose exec -T postgres createdb -U course course_hw04_repeat
```

Во всех командах подготовки и выполнения замените course_hw04 на course_hw04_repeat. Примените schema.sql, seed.sql, затем свои файлы по порядку. Исходная база сохранится. Файлы schema.sql, seed.sql и prepare-mixed.sql выполняйте один раз в каждой новой базе.

Готовое решение можно запустить в ещё одной базе по [инструкции self-check](self-check/README.md). Ваша рабочая база сохранится. SQL-пробы проверяют ограничения и перенос сумм. Обоснование решений и план выпуска сравните с ключом самостоятельно.

## Остановка стенда

Выйдите из psql и выполните:

```sh
docker compose down
```

Данные сохраняются в именованном томе и доступны после следующего запуска.

## Если PostgreSQL уже установлен

Создайте отдельную пустую базу и примените schema.sql и seed.sql через psql. Затем выполняйте свои файлы в том же порядке. Все объекты находятся в схеме hw04. Примеры проверены на PostgreSQL 18.4. Перед такой миграцией на рабочей системе нужно подтвердить остановку старых приложений и импорта, оценить нагрузку и длительность блокировок на её объёме данных.

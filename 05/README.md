# Пакет домашнего задания 5

В задании нужно подобрать индексы для сервиса заказов, сравнить два набора на чтении и записи и подготовить их установку в работающей базе. Условия и критерии находятся в [homework.md](homework.md). Ориентировочное время после запуска среды — 4–6 часов для мидла и 2–3 часа для сеньора.

Для работы нужен Docker с Compose v2. psql запускается внутри контейнера, схема и данные включены в пакет. SQL можно менять с сохранением требуемых результатов. Число и размер индексов выбирайте по замерам. [Ключ](answer-key.md) и self-check открывайте после выполнения задания.

## Состав

| Файл | Для чего |
| --- | --- |
| [homework.md](homework.md) | Задания и критерии оценки |
| [compose.yaml](compose.yaml), [schema.sql](schema.sql), [seed.sql](seed.sql), [sanity.sql](sanity.sql) | Стенд, данные и проверка загрузки |
| [queries.sql](queries.sql) | Девять исходных EXPLAIN |
| [01-indexes.sql](01-indexes.sql), [02-alternative.sql](02-alternative.sql) | Ваши наборы A и B |
| [comparison.sql](comparison.sql) | Проверка значений, типов, дублей и порядка |
| [keyset.sql](keyset.sql), [checks.sql](checks.sql) | Пагинация и свои проверки |
| [fixtures/](fixtures) | Обновление заказов, поздние события и измерение записи |
| [03-rollout.sql](03-rollout.sql) | Сценарий установки индексов |
| [report-template.md](report-template.md) | Шаблон отчёта |
| [answer-key.md](answer-key.md), [self-check/](self-check/README.md) | Разбор двух решений и SQL для самопроверки |
| [images/README.md](images/README.md) | Образ Docker, в том числе без интернета |

## 1. Подготовка

Откройте терминал в корне этой папки. Все следующие команды выполняются отсюда:

```sh
docker compose up -d --wait
docker compose exec -T postgres psql -X -U course -d course_hw05 -v ON_ERROR_STOP=1 -c 'SELECT version(), current_database();'
docker compose exec -T postgres psql -X -U course -d course_hw05 -v ON_ERROR_STOP=1 -f /work/schema.sql -f /work/seed.sql -f /work/sanity.sql
```

Стенд использует PostgreSQL 18.4. Пользователь — course, пароль — course_local, база — course_hw05, схема — hw05. Порт компьютера не публикуется. Данные сервера хранятся в именованном Docker volume, файлы папки примонтированы в /work только для чтения. Редактируйте их на компьютере.

Загрузка создаёт 300000 заказов, 100000 покупателей и 600000 событий. Магазину 1 принадлежит половина заказов, магазину 42 — около 1500. Для образа, двух наборов данных и индексов потребуется около 2 ГБ свободного места. Данные сгенерированы для задания.

schema.sql и seed.sql запускаются **один раз в пустой базе**. Повторный запуск в той же базе завершится ошибкой: объекты и строки уже существуют. Для нового опыта создайте новую базу по разделу 4. После повторного запуска контейнера существующий volume сохраняет состояние.

## 2. Исходный замер и набор A

Откройте [queries.sql](queries.sql), запишите ожидаемый эффект индексов и заполните 01-indexes.sql. Для исходных планов можно открыть psql:

```sh
docker compose exec postgres psql -X -U course -d course_hw05 -v ON_ERROR_STOP=1
```

Внутри psql:

```sql
SET TIME ZONE 'UTC';
\pset pager off
```

Запускайте запросы из queries.sql по отдельности: один раз для прогрева и ещё три раза для измерений. Сохраняйте планы, полные результаты, определения и размеры индексов. При подсчёте buffers учитывайте, что родительский узел уже включает работу дочерних. Все исходные планы можно сохранить командой:

```sh
mkdir -p results
docker compose exec -T postgres psql -X -U course -d course_hw05 -v ON_ERROR_STOP=1 -f /work/queries.sql > results/A-before.txt
```

До применения индексов запустите в **новой сессии** comparison.sql. Он сам выполнит 01-indexes.sql:

```sh
docker compose exec -T postgres psql -X -U course -d course_hw05 -v ON_ERROR_STOP=1 -f /work/comparison.sql > results/A-comparison.txt
```

Скрипт сравнивает результаты девяти запросов. При совпадении все значения changed_rows равны нулю, в конце выводится PASS. Изменение названий или типов колонок вызывает ошибку. Проверка работает и с пустым DDL; влияние индексов на производительность измеряйте отдельно. Если переписываете SELECT, замените его в соответствующем AFTER-блоке comparison.sql. Изменения queries.sql автоматически туда не переносятся.

После сверки индексы уже созданы, повторный запуск DDL может вызвать ошибку. Снимите планы AFTER до обновления данных, реализуйте keyset.sql и свои проверки. Определения и размеры индексов можно получить так:

```sql
SELECT indexname, indexdef FROM pg_indexes WHERE schemaname='hw05' ORDER BY indexname;
SELECT indexrelid::regclass AS name, pg_relation_size(indexrelid) AS bytes
FROM pg_index WHERE indrelid IN ('hw05.orders'::regclass,'hw05.customers'::regclass,'hw05.events'::regclass)
ORDER BY 1;
```

## 3. Последовательность изменений

После измерений с набором A выполните каждый сценарий по одному разу:

1. fixtures/01-busy-orders.sql. Повторите QF/QW **до ручного VACUUM**, сравните обращения к heap. Затем VACUUM (ANALYZE) hw05.orders и ещё раз чтение.
2. fixtures/02-late-events.sql. Повторите QT, сверьте точный count на текущих данных. При использовании сводок BRIN измерьте также после их суммирования.
3. fixtures/03-write-cost.sql — **последним**, после замеров чтения. Сохраните время, buffers и WAL отдельно для INSERT и UPDATE.

Обновление заказов запускается так:

```sh
docker compose exec -T postgres psql -X -U course -d course_hw05 -v ON_ERROR_STOP=1 -f /work/fixtures/01-busy-orders.sql > results/A-busy.txt
```

После повторного чтения:

```sh
docker compose exec -T postgres psql -X -U course -d course_hw05 -v ON_ERROR_STOP=1 -c 'VACUUM (ANALYZE) hw05.orders;'
```

Аналогично запускайте два других файла fixtures через -f. Первые два изменяют данные с COMMIT; поздняя доставка повторно в той же базе конфликтует по PK. Третий выполняет ROLLBACK: значения восстанавливаются, выполненная работа со страницами и WAL остаётся. Для повторного измерения записи создайте новую базу. После изменений не запускайте sanity.sql как проверку исходных объёмов: событий уже 650000.

## 4. Набор B и повторение

Для B создайте независимую пустую базу в том же контейнере:

```sh
docker compose exec -T postgres createdb -U course course_hw05_b
docker compose exec -T postgres psql -X -U course -d course_hw05_b -v ON_ERROR_STOP=1 -f /work/schema.sql -f /work/seed.sql -f /work/sanity.sql
```

Повторите исходные планы. Примените B через сверку:

```sh
docker compose exec -T postgres psql -X -U course -d course_hw05_b -v ON_ERROR_STOP=1 -v index_file=02-alternative.sql -f /work/comparison.sql > results/B-comparison.txt
```

Далее повторите **ту же последовательность** замеров и fixtures с -d course_hw05_b. Для дополнительных прогонов создавайте базы с новыми именами, например course_hw05_repeat1. Предыдущие базы сохранятся. Если нужно освободить место, сначала сохраните результаты, затем удалите ненужные базы.

Для проверки установки индексов создайте ещё одну исходную базу, например course_hw05_release, примените schema.sql/seed.sql и ваш 03-rollout.sql. Команды CONCURRENTLY не оборачивайте в BEGIN или параметр psql --single-transaction. Перед удалением старого индекса проверьте новый индекс и остальные запросы, которые использовали старый.

## 5. Сдача и остановка

Скопируйте report-template.md в report.md. Сдайте свои пять SQL-файлов и отчёт, приложите выбранные планы/результаты из results/. Папка results/ исключена из Git. Приложите выбранные планы и результаты отдельно либо добавьте их через git add -f. Собственные SQL и report.md отслеживаются обычным образом.

Команды для запуска примеров решений находятся в [self-check](self-check/README.md). Папка пакета готова для загрузки в Git; образ Docker при необходимости передаётся отдельно.

```sh
docker compose down
```

Контейнер остановится, volume с базами сохранится. При следующем up не повторяйте загрузку в существующих базах.

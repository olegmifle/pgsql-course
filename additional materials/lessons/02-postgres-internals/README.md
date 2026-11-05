# Урок 2. Что происходит под капотом

Проследим путь чтения и записи: страницы в памяти, версии строк, снимки транзакций, WAL, checkpoint и VACUUM. Нужны два постоянных подключения: A — чтение, B — изменения.

## Подготовка

Из этой папки выполните:

```sh
docker compose up -d --wait
docker compose exec -T postgres psql -X -U course -d course_underhood -v ON_ERROR_STOP=1 -f /work/sql/00-setup.sql
```

Загрузка создаёт схему `underhood` и расширения `pg_buffercache`, `pageinspect`, `pg_walinspect`. Настройки фоновой записи и autovacuum на отдельных таблицах изменены для воспроизводимости опытов.

В двух терминалах откройте одинаковое подключение:

```sh
docker compose exec postgres psql -X -U course -d course_underhood
```

В каждом `psql` выполните `\pset pager off`. Команды таблиц ниже вводятся внутри соответствующего `psql`.

## 1. Страницы и shared buffers

Все шаги выполняйте в B:

| Порядок | Команда | Что сравнить |
| --- | --- | --- |
| 1 | `\i /work/sql/10-buffers-evict.sql` | Страницы таблицы вытеснены из shared buffers |
| 2 | `\i /work/sql/11-buffers-read.sql` | Первый проход загружает страницы |
| 3 | Ещё раз `\i /work/sql/11-buffers-read.sql` | Повтор чаще использует `shared hit` |
| 4 | `\i /work/sql/12-buffers-dirty.sql` | UPDATE оставляет изменённую страницу: `dirty_pages > 0` |
| 5 | `\i /work/sql/13-checkpoint.sql` | CHECKPOINT записывает изменённые страницы |

`cached_pages` — страницы таблицы в буферном кеше PostgreSQL; `dirty_pages` — изменённые страницы, ещё требующие записи. `shared read` означает загрузку в shared buffers: данные могли прийти из кеша ОС. Вытеснение в этом опыте кеш ОС не очищает.

## 2. Две версии строки и один снимок

Соблюдайте порядок и сохраняйте оба подключения:

| Порядок | Окно | Команда | Наблюдение |
| --- | --- | --- | --- |
| 1 | A | `\i /work/sql/20-reader-start.sql` | RR-снимок, `progress = 20`; транзакция остаётся открытой |
| 2 | B | `\i /work/sql/21-writer-update.sql` | Новая версия `progress = 40`, без COMMIT |
| 3 | A | `\i /work/sql/22-reader-observe.sql` | Введите `writer_xid`, напечатанный в B; A видит 20 |
| 4 | B | `\i /work/sql/23-writer-commit.sql` | B фиксирует запись и видит 40 |
| 5 | A | Повторите `\i /work/sql/22-reader-observe.sql` | A по прежнему снимку видит 20 |

`ctid` — физический адрес версии; `xmin` — создавшая её транзакция; `xmax` участвует в информации об удалении/изменении и блокировках. Не трактуйте любое ненулевое `xmax` как доказательство удаления. Представление `version_page` читает физическую страницу, поэтому может показать версии, которых обычный SELECT не видит. Подтверждение B не заменяет уже установленный RR-снимок A.

## 3. WAL, COMMIT и checkpoint

Пока A остаётся открытой, в B выполните:

```sql
\i /work/sql/30-wal.sql
```

Скрипт меняет независимую таблицу `wal_demo`, находит её записи WAL и COMMIT. Проверьте `commit_record_is_flushed = t`. LSN — позиция в журнале; `wal_bytes_in_interval` — разность позиций, а не размер одной строки.

Сравните `wal_page_locations`: содержимое страницы в shared buffers и файле relation до/после CHECKPOINT. При обычных включённых `fsync` и `synchronous_commit` фиксация ждёт устойчивого WAL; запись всех изменённых страниц таблицы к моменту COMMIT не требуется. На стенде фоновая запись отложена, чтобы это различие было видно.

## 4. Что удерживает VACUUM

| Порядок | Окно | Команда | Наблюдение |
| --- | --- | --- | --- |
| 1 | B | `\i /work/sql/40-vacuum.sql` | Старый снимок A ещё требует прежнюю версию |
| 2 | A | `\i /work/sql/41-reader-commit.sql` | Снимок освобождён; пока не читайте таблицу заново |
| 3 | B | Повторите `\i /work/sql/40-vacuum.sql` | Прежнюю версию теперь можно очистить |
| 4 | A | `\i /work/sql/42-reader-new-snapshot.sql` | Новое чтение видит 40 |

Обычный VACUUM освобождает место для повторного использования. В этом опыте `TRUNCATE FALSE` исключает обрезание файла, поэтому неизменный `heap_bytes` не означает отсутствия очистки.

## 5. Дополнительно: ожидание одной строки

В A выполните `\i /work/sql/50-reader-lock.sql`. В B выполните `\i /work/sql/51-writer-wait.sql`: команда начнёт ждать. Пока B ждёт, в A выполните `\i /work/sql/52-reader-release.sql`. Видны блокер и COMMIT, после которого B продолжает и получает `counter = 11`. Не отправляйте команды в ожидающее B до возврата приглашения.

## Завершение и повтор

После опытов в B выполните `\i /work/sql/90-finish.sql`: это вернёт autovacuum таблиц. Затем закройте A/B через `\q` и остановите стенд: `docker compose down`.

`00-setup.sql` применяется один раз. Для повтора закройте прежние подключения, создайте пустую базу и загрузите туда тот же setup:

```sh
docker compose exec -T postgres createdb -U course course_underhood_repeat
docker compose exec -T postgres psql -X -U course -d course_underhood_repeat -v ON_ERROR_STOP=1 -f /work/sql/00-setup.sql
```

При подключении обоих окон указывайте новую базу. Внутреннее имя схемы остаётся `underhood`. Для следующего повтора выберите новое имя базы.

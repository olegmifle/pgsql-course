# Самопроверка после своей попытки

Начните с [ключа](../answer-key.md). Это один рабочий вариант диагностики, а не автоматический экзамен вашего отчёта. Сравниваются смысл, покрытие и свидетельства.

## Готовые запросы

| Файл | Как использовать |
| --- | --- |
| [health.sql](health.sql), [parts/](parts) | Read-only общий отчёт, в том числе от hw08_monitor |
| [window.sql](window.sql) | Дельты в том же O, где созданы оба TEMP-снимка |
| [window-cases.sql](window-cases.sql) | Reset/new/disappeared на TEMP-копиях, каждый опыт откатывается |
| [locks.sql](locks.sql) | Рёбра ожидания и идентичность участников |
| [maintenance.sql](maintenance.sql) | Таблица, прогресс, xmin, slots и prepared |
| [improve.sql](improve.sql) | Одно исправление ленты; только для изолированного стенда |

## Проверить общий отчёт

Из корня пакета при запущенном Compose:

```sh
docker compose exec -T postgres psql -X -U hw08_monitor -d course_hw08 -v ON_ERROR_STOP=1 -f /work/self-check/health.sql
```

Локальный монитор имеет pg_monitor и read-only по умолчанию. Тексты/метрики других сессий — привилегированные сведения. Строки locks/progress могут быть пустыми вне инцидента; это не подтверждает отсутствия прошлой проблемы.

## Воспроизвести эталонный маршрут

Создайте **другую свежую БД**, чтобы не менять свою работу:

```sh
docker compose exec -T postgres createdb -U course hw08_reference
docker compose exec -T postgres psql -X -U course -d hw08_reference -v ON_ERROR_STOP=1 -f /work/schema.sql -f /work/seed.sql -f /work/sanity.sql
```

Откройте A/B/O в hw08_reference с теми же init, выполните [scenarios.md](../scenarios.md). Подставьте self-check/window.sql вместо 02-window.sql; self-check/locks.sql вместо 03-locks.sql; self-check/maintenance.sql вместо 04-maintenance.sql; self-check/improve.sql вместо своего DDL. Не переключайте одну сессию на другую БД, оставив остальные в прежней.

После первого сравнения в **том же O**:

```sql
\i /work/self-check/window-cases.sql
```

Ожидаются пометки reset/recreated, new entry, disappeared. У этих строк нет численных дельт. Скрипт не вызывает pg_stat_statements_reset, не удаляет реальные записи статистики и после ROLLBACK восстанавливает TEMP-снимки. Начало/конец времени и глобальные метаданные дополнительно читаются из hw08_window_meta_start/end.

Ни один PASS технической фикстуры не оценивает вашу интерпретацию или пригодность алертов. Для этого используйте [критерии условия](../homework.md) и [шаблон](../report-template.md).

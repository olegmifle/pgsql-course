# Самопроверка

После выполнения задания прочитайте [разбор](../answer-key.md). В этой папке находятся два примера наборов индексов, запрос с курсором и пример установки индекса. Их можно выполнить через psql в отдельных базах и сравнить со своим решением.

## Как воспроизвести

Из корня пакета с запущенным Compose создайте две новые базы:

```sh
docker compose exec -T postgres createdb -U course hw05_reference_a
docker compose exec -T postgres createdb -U course hw05_reference_b
docker compose exec -T postgres psql -X -U course -d hw05_reference_a -v ON_ERROR_STOP=1 -f /work/schema.sql -f /work/seed.sql -f /work/sanity.sql
docker compose exec -T postgres psql -X -U course -d hw05_reference_b -v ON_ERROR_STOP=1 -f /work/schema.sql -f /work/seed.sql -f /work/sanity.sql
```

Снимите исходные планы, затем примените каждый набор через comparison.sql:

```sh
docker compose exec -T postgres psql -X -U course -d hw05_reference_a -v ON_ERROR_STOP=1 -v index_file=self-check/01-lean.sql -f /work/comparison.sql
docker compose exec -T postgres psql -X -U course -d hw05_reference_b -v ON_ERROR_STOP=1 -v index_file=self-check/02-cover.sql -f /work/comparison.sql
```

В каждой базе ожидаются девять нулевых значений changed_rows и сообщение PASS. Планы запросов снимите через queries.sql. Для пагинации используйте [keyset.sql](keyset.sql); обновления и запись запускайте в порядке из основного README. При сравнении со своими результатами учитывайте различия в окружении и состоянии страниц.

[03-rollout.sql](03-rollout.sql) создаёт один новый индекс и удаляет исходный. Для его запуска нужна **ещё одна исходная база** со схемой и данными. Выполните файл вне транзакционной обёртки один раз. Для установки всего набора A или B составьте аналогичную последовательность для каждого индекса.

## Сверка собственного решения

Запустите корневой [comparison.sql](../comparison.sql) до применения DDL. Затем проверьте границы страниц, JSON null, результат после добавления событий и восстановление значений после ROLLBACK. Производительность оцените по планам и измерениям чтения и записи.

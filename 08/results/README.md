# Сохранить свидетельства

Команды выполняются из корня пакета; в примерах база course_hw08. Для другого опыта замените её во всех shell-командах. Каталог /work внутри контейнера read-only, поэтому результаты сначала пишутся в /tmp контейнера, затем копируются на компьютер.

## Вывод в том же интерактивном O

```sql
\o /tmp/hw08-window-before.txt
\i /work/02-window.sql
\o
```

Это сохраняет результат анализа, не закрывая подключение с TEMP-снимками. Затем в shell:

```sh
mkdir -p results
docker compose cp postgres:/tmp/hw08-window-before.txt results/window-before.txt
```

Аналогично сохраняйте window-after.txt, blockers-before/cancel/after и maintenance-before/after. Сами исходные счётчики можно вывести в том же O: `TABLE hw08_window_start;`, `TABLE hw08_window_end;` и TABLE для hw08_window_meta_start/end. Назовите источник каждого файла. Сохранять данные нужно до следующего window-start/end, которые заменят только ваши TEMP-таблицы.

## VACUUM VERBOSE

Сообщения VERBOSE идут в stderr; `\o` их не сохраняет. Оставив A открытой в нужной фазе, из shell выполните:

```sh
docker compose exec -T postgres psql -X -U course -d course_hw08 -v ON_ERROR_STOP=1 -f /work/fixtures/vacuum.sql > results/vacuum-before.txt 2>&1
```

После COMMIT A повторите эту команду с именем vacuum-after.txt. Это отдельное короткое подключение к той же БД. Оно заменяет соответствующий запуск VACUUM в O, а не добавляет лишний второй до сохранения первого вывода.

## Логи и расписание

```sh
docker compose logs --no-color --since 10m postgres > results/deadlock.log
```

Запишите порядок A/B/O и время опытов в schedule.txt. Полезно сохранить исходный лог и отдельно короткий фрагмент с пояснением. Избегайте случайного включения паролей и чужих параметров.

Сдавайте собственные результаты. Изменения в results исключены из Git; добавьте выбранные файлы явно через `git add -f results/ИМЯ` либо приложите отдельно. Этот README остаётся отслеживаемым.

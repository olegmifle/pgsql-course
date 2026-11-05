# Пакет домашнего задания 6

**Три конкурентные операции сервиса заказов.** Сложно для middle, интересно для senior. Ориентир после подготовки среды: 6–8 часов / 3–5 часов. Начните с [условия](homework.md).

Нужен Docker с Compose v2; на macOS команды ниже используют Colima и явный контекст colima-pgcourse06-live. psql уже внутри контейнера; Python, PostgreSQL на компьютере и скачивание датасета не требуются. Папку пакета можно целиком выгрузить в Git. Ключ и эталоны self-check предназначены для разбора **после собственной попытки**.

Задание продолжает три решения из лекции: общее правило по нескольким строкам, идентичность повторного запроса и короткое назначение работы. В квоте нужно обнаружить аномалию сериализации, в списании — различить отказ транзакции и неизвестный исход COMMIT, в очереди — отделить защиту состояния БД от внешнего эффекта.

## Состав

| Файл | Для чего |
| --- | --- |
| [homework.md](homework.md) | Контракты, три задачи, сдача и оценка |
| [compose.yaml](compose.yaml), [schema.sql](schema.sql), [seed.sql](seed.sql), [sanity.sql](sanity.sql) | Готовый PostgreSQL и небольшой исходный набор |
| [scenarios.md](scenarios.md), [observer.sql](observer.sql) | Управляемые чередования и диагностика ожиданий |
| [01-reservations.sql](01-reservations.sql), [02-debit.sql](02-debit.sql), [03-queue.sql](03-queue.sql) | Ваши реализации |
| [checks.sql](checks.sql) | Проверка текущих бизнес-правил и место для своих проб |
| [fixtures/](fixtures) | Отказы записи, очередь, пополнение, истечение аренды |
| [retry-policy.md](retry-policy.md), [external-policy.md](external-policy.md) | Ваша политика повторов и внешнего действия |
| [report-template.md](report-template.md) | Короткий отчёт со свидетельствами |
| [answer-key.md](answer-key.md), [self-check/](self-check/README.md) | Разбор и один рабочий вариант каждого протокола |
| [images/README.md](images/README.md) | Образ Docker, в том числе без интернета |

## Подготовка

Все команды выполняйте из корня **папки пакета**, где лежит compose.yaml. При использовании Colima сначала запустите профиль:

```sh
colima start --profile pgcourse06-live --activate=false
```

Затем запустите стенд и загрузите исходные данные:

```sh
docker --context colima-pgcourse06-live compose up -d --wait
docker --context colima-pgcourse06-live compose exec -T postgres psql -X -U course -d course_hw06 -v ON_ERROR_STOP=1 -f /work/schema.sql -f /work/seed.sql -f /work/sanity.sql
```

На Linux или с Docker Desktop используйте те же команды без `--context colima-pgcourse06-live`; вызов colima start не требуется.

PostgreSQL 18.4, база course_hw06, пользователь course, локальный пароль course_local. Схема hw06. Порт компьютера не публикуется. Данные сохраняются в именованном Docker volume; файлы пакета доступны в /work только для чтения. Редактируйте их на компьютере. Контейнеру достаточно обычных ресурсов Docker; большой датасет для этой работы не нужен.

schema.sql и seed.sql запускайте **один раз в пустой базе**. Они не сбрасывают прежнюю работу; повтор завершится ошибкой. sanity.sql проверяет только исходное состояние. Для дальнейших состояний используйте checks.sql. Перезапуск контейнера не очищает базу.

Создайте отдельную базу для каждого независимого сценария. Например:

```sh
docker --context colima-pgcourse06-live compose exec -T postgres createdb -U course hw06_stock
docker --context colima-pgcourse06-live compose exec -T postgres psql -X -U course -d hw06_stock -v ON_ERROR_STOP=1 -f /work/schema.sql -f /work/seed.sql -f /work/sanity.sql
```

Для других опытов замените имя на hw06_quota, hw06_cancel, hw06_debit, hw06_fail, hw06_retry, hw06_deadlock, hw06_queue и т. п. Повторное createdb с существующим именем завершится ошибкой. Создавайте новое имя; скрытого удаления вашей работы нет.

## Применение решения

После заполнения заготовок загрузите нужные функции в выбранную базу:

```sh
docker --context colima-pgcourse06-live compose exec -T postgres psql -X -U course -d hw06_stock -v ON_ERROR_STOP=1 -f /work/01-reservations.sql
```

Аналогично для 02-debit.sql и 03-queue.sql, с нужным именем базы. Пустая заготовка ничего не реализует: отсутствие ошибки при её загрузке не означает готовность решения. Если выбрали приложение, используйте те же данные и результаты, укажите команду и границы соединений.

## Две сессии и наблюдатель

В **трёх отдельных терминалах** откройте psql к **одной и той же выбранной базе**:

```sh
docker --context colima-pgcourse06-live compose exec postgres psql -X -U course -d hw06_stock
```

В первом подключении:

```sql
SET application_name='hw06-A';
SET search_path=hw06,public;
\pset pager off
\set VERBOSITY verbose
\set ON_ERROR_STOP off
SET lock_timeout='5min';
SET statement_timeout='10min';
```

Во втором те же настройки, но application_name='hw06-B'. В третьем application_name='hw06-observer'. Большие учебные таймауты позволяют вручную переключаться между терминалами, это не рекомендация для рабочего приложения.

Дальше выполняйте этапы [scenarios.md](scenarios.md). При ожидающей команде B не печатайте в её терминале COMMIT «вперёд»; сначала наблюдатель, затем завершение A, после ответа B — её COMMIT. Ожидание подтверждайте через `\i /work/observer.sql`. Видеть другие сессии можно только при подключении к той же базе.

Для проверки после завершения A/B в наблюдателе:

```sql
\i /work/checks.sql
```

После ожидаемой ошибки в явной транзакции выполните ROLLBACK. Отрицательный контроль обязан дать FAIL, исправленный — PASS и ожидаемые результаты. Не запускайте checks.sql во время частично завершённого сценария как финальное доказательство. В исходном наборе есть четыре ранее созданных резерва; они должны участвовать в суммах.

## Готовые отказы и очередь

В нужной базе hw06_fail включите ошибку:

```sh
docker --context colima-pgcourse06-live compose exec -T postgres psql -X -U course -d hw06_fail -v ON_ERROR_STOP=1 -f /work/fixtures/reservation-error-on.sql
```

Вызовите reserve внутри BEGIN, получите P0001, выполните ROLLBACK, проверьте правила из нового подключения. Отключение:

```sh
docker --context colima-pgcourse06-live compose exec -T postgres psql -X -U course -d hw06_fail -v ON_ERROR_STOP=1 -f /work/fixtures/reservation-error-off.sql
```

Для debit используются outbox-error-on.sql и outbox-error-off.sql. Файлы *-on.sql включайте один раз до соответствующей пробы; повторное создание активного триггера даст ошибку. *-off.sql можно применять повторно. Пользователь course учебный суперпользователь и может включать эти механизмы; это не образец прав приложения.

Для очереди создайте свежую hw06_queue, загрузите schema/seed/sanity, затем fixtures/queue.sql и свой 03-queue.sql. queue.sql применяйте один раз: создаёт три approved-списания организации 9, кошелёк 3 получает 70, появляются три jobs. В рабочем приложении jobs создаёт debit; эта фикстура позволяет решать третий блок независимо.

Для истечения аренды в наблюдателе задайте реальный id полученного задания:

```sql
\set job_id 1
\i /work/fixtures/expire.sql
```

Это управляемое изменение времени опыта, не реализация очистки очереди. Не ждите физического истечения аренды. fixtures/topup.sql однократно добавляет 80 в кошелёк 1 и журнал wallet_credits; повтор добавит ещё 80. Исходный баланс не переписывается.

## Сохранение и сдача

Скопируйте report-template.md в report.md. Сохраните SQL, политики и выбранные свидетельства. Например, итоговые состояния из отдельной сессии:

```sh
mkdir -p results
docker --context colima-pgcourse06-live compose exec -T postgres psql -X -U course -d hw06_stock -v ON_ERROR_STOP=1 -f /work/checks.sql > results/stock-final.txt
```

Расписания интерактивных сессий сохраните текстом с подписями A/B/observer и порядком шагов. results/ исключена из Git; выбранные файлы приложите отдельно либо добавьте через git add -f. Собственные SQL и report.md отслеживаются обычным образом.

После работы:

```sh
docker --context colima-pgcourse06-live compose down
```

Контейнер остановится, volume сохранится. При новом up продолжайте существующую базу или создайте новую для чистого опыта.

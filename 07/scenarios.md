# Управляемые сценарии

Везде используется база course_hw07. Основная команда подключения и выбор Compose project описаны в [руководстве](README.md). Начинайте каждый основной блок на свежем project. Имена и номера ниже относятся только к этой работе.

## R1. ANY 1 и выбранный читатель

1. В shell: `sh /work/lab/control.sh pause r2` через docker compose exec -T lab. Затем sync any1.
2. В psql primary (A):

```sql
SET application_name='hw07-writer';
BEGIN;
SET LOCAL synchronous_commit='remote_apply';
UPDATE hw07.orders SET status='paid' WHERE id=1001;
INSERT INTO hw07.progress VALUES(101,'first read fence');
COMMIT;
SELECT pg_current_wal_insert_lsn() AS min_lsn;
```

3. На r1 и r2 выполните SELECT заказа 1001 и метки progress.id=101. Сохраните min_lsn из primary, replay LSN каждого узла и результат чтения. Числовой id=101 относится к progress, не к orders.
4. Через observer на primary посмотрите sync_state и replay_lsn. Для ANY участник может иметь sync_state=quorum; это не отдельный leader-election протокол.

## R2. ANY 2 и старый снимок

R2 продолжается после R1, r2 пока paused. Откройте на r1 сессию B:

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;
SELECT status FROM hw07.orders WHERE id=1001;
SELECT count(*) FROM hw07.progress WHERE id=102;
```

В shell установите sync any2. В A на primary:

```sql
BEGIN;
SET LOCAL synchronous_commit='remote_apply';
UPDATE hw07.orders SET status='cancelled' WHERE id=1001;
INSERT INTO hw07.progress VALUES(102,'second read fence');
COMMIT;
```

COMMIT ждёт. Не посылайте команды в этот терминал заранее. В observer на primary выполните observer.sql и сохраните SyncRep. Через отдельный shell выполните resume r2. После ответа A сохраните новый min_lsn. В старой B повторите оба SELECT, затем COMMIT и такие же SELECT в новой транзакции. Сравните с r2.

## R3. Ветка deadline

Верните sync any1, приостановите r2. На primary измените статус 1001 на paid, запишите progress=103 одной транзакцией и получите min_lsn после COMMIT. Для своего алгоритма чтения выберите именно r2. В пределах согласованного бюджета он должен либо перейти на primary, либо вернуть явную ошибку свежести. Условный SELECT по orders без ожидания не должен выдаваться за успешное строгое чтение.

Возобновите r2 и выполните успешную ветку по этому же токену с новым снимком. В финале resume r1/r2 и sync async. Для даты используйте order 2002, created_at=2026-11-02 00:30:00+00; до этой проверки данные уже одинаковы.

## L1–L4. Logical apply

На свежем project, синхронные физические ответы не включены. Каждую команду запускайте **один раз**, дожидайтесь результата и исправляйте состояние до следующей.

```sh
docker compose exec -T lab sh /work/lab/control.sh fixture missing
docker compose exec -T lab sh /work/lab/control.sh fixture conflict
docker compose exec -T lab sh /work/lab/control.sh fixture ddl
docker compose exec -T lab sh /work/lab/control.sh fixture fk
```

После missing ищите заказ 1001, метку 1101 и confl_update_missing. После conflict — 1201, 1202, метку 1203 и журнал. После ddl — колонку currency, 1301 и метку 1302. После fk — заказ 1401, tenant 99 и метку 1402. Проверяйте, что нужная метка действительно дошла; произвольная пауза не заменяет наблюдение состояния.

В начале отдельного опыта по генератору вызовите nextval('hw07.generated_ids_id_seq') на primary и subscriber. Запишите, какой номер уже потреблён вызовом. План подготовки генератора должен учитывать существующие id, прекращение старой записи и момент запуска нового writer.

## P. Ошибочное удаление и PITR

На свежем project:

```sh
docker compose exec -T lab sh /work/lab/control.sh incident
docker compose exec -T lab sh /work/lab/control.sh recover
```

Incident сначала создаёт 3001, затем restore point, выполняет удаление и корректные поздние операции, переключает WAL и ждёт появления нужного архивного сегмента. Recover проверяет исходную физическую копию, создаёт отдельный каталог и запускает restored. Существующий каталог восстановленной базы он не перезаписывает. Порты и действующий primary сохраняются.

Сравните:

| Узел | Tenant 42 | Заказ 2001 | Заказ 3002 |
| --- | --- | --- | --- |
| Primary после incident | 0 заказов | cancelled | paid |
| Restored на цели | Что ожидали получить? | Какой прежний статус? | Должен ли уже существовать? |

Восстановленная база остаётся в recovery с paused replay и используется для чтения. Не вызывайте pg_wal_replay_resume или promotion: цель опыта — получить данные на выбранном моменте. Выгрузите orders/items, примените своё исправление на primary и повторите его. Сравните все текущие строки и проверки связей/сумм, а не только общее количество.

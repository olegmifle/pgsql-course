# Управляемые сценарии A/B

Сначала настройте три сессии по [README](README.md). Каждый раздел с пометкой «свежая база» начинается с schema.sql/seed.sql/sanity.sql. При переносе между базами переподключите все три терминала и повторите настройки. Исправленные опыты требуют ваших реализаций; эталоны находятся в self-check после попытки.

## S1. Лишний резерв при неотрицательном остатке

Свежая база, реализации не нужны. A и B читают одну единицу, затем записывают заранее вычисленный ноль.

A1:

```sql
BEGIN;
SELECT available FROM inventory WHERE sku=100;
```

B1: те же две команды. Обе видят 1.

A2:

```sql
UPDATE inventory SET available=0 WHERE sku=100;
INSERT INTO reservations(organization_id,sku,qty) VALUES(8,100,1);
COMMIT;
```

B2: те же команды, но organization_id=9. Наблюдатель запускает checks.sql: stock нарушен. Исследуйте, почему CHECK available>=0 это допускает.

## S2. Write skew квоты и один INSERT

Свежая база. A1 и B1:

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT count(*) FROM reservations WHERE organization_id=7 AND status='active';
```

Обе видят 4. A2:

```sql
UPDATE inventory SET available=available-1 WHERE sku=200;
INSERT INTO reservations(organization_id,sku,qty)
SELECT 7,200,1 WHERE (SELECT count(*) FROM reservations
 WHERE organization_id=7 AND status='active')<5;
```

B2: те же команды, но sku=300 в UPDATE и SELECT. Выполните обе вставки **до любого COMMIT**. Затем A3 COMMIT, B3 COMMIT. checks.sql показывает quota, товарные суммы остаются корректны. Снова проведите опыт в новой базе с READ COMMITTED. Что гарантирует один SQL и что он здесь не защищает?

## S3. Исправление товара и квоты

Свежая база с вашей реализацией. A1:

```sql
BEGIN;
SELECT reserve(8,100,1);
```

Не завершайте A. B1:

```sql
BEGIN;
SELECT reserve(9,100,1);
```

При эталонном RC-протоколе B ждёт; observer: `\i /work/observer.sql`. A2 COMMIT, затем ответ B, B2 COMMIT. Ожидается один id, один NULL, остаток 0 и один новый active-резерв.

В другой свежей базе повторите с A=reserve(7,200,1), B=reserve(7,300,1). Ожидается ровно одно занятое место из оставшихся, active=5. Для другой изоляции/протокола допустим отказ 40001 с полным повтором: покажите результат завершённых операций и своё условие запуска.

## S4. Две отмены и ошибка INSERT

Свежая база с reserve/cancel. В A сохраните id **одним** выполнением запроса:

```sql
SELECT reserve(8,100,1) AS res_id
\gset
\echo :res_id
BEGIN;
SELECT cancel(:res_id);
```

Здесь перед `\gset` нет точки с запятой: команда исполняет SELECT и сохраняет результат. Скопируйте выведенный id в B, выполните BEGIN и SELECT cancel(этот_id). После проверки ожидания A делает COMMIT, затем B завершает свою транзакцию. Результаты true/false, available=1. Отдельно cancel для неизвестного id должен вернуть false.

Для ошибки используйте другую свежую базу и reservation-error-on.sql по README. A: BEGIN; SELECT reserve(8,100,1);. Получите P0001. SELECT 1 в той же попытке даст 25P02; выполните ROLLBACK. Новый observer проверяет отсутствие нового резерва и исходный остаток. Отключите триггер и убедитесь, что новая попытка проходит.

## S5. Одновременный повтор списания

Свежая база с debit. A1:

```sql
BEGIN;
SELECT * FROM debit(7,'checkout-42',1,30);
```

B1: BEGIN; тот же SELECT. Observer показывает ожидание. A2 COMMIT; затем ответ B и B2 COMMIT. Один approved-эффект, один job, оба ответа одинаковы. Затем в отдельной транзакции выполните debit(7,'checkout-43',1,10) и повторите checkout-42. Сохранённый balance_after первого запроса остаётся 70, текущий баланс уже 60.

Повтор checkout-42 с amount=31 даёт 22023. Для изменения wallet_id создайте второй кошелёк той же организации: `INSERT INTO wallets VALUES(4,7,100,100);`, повторите ключ с wallet_id=4. Также 22023. Тот же ключ для организации 8 и её wallet_id=2 — самостоятельное корректное списание.

В новой базе повторите одновременный вызов одного ключа, но вместо COMMIT A выполните ROLLBACK. B должен получить право выполнить списание сам; после его COMMIT останется один эффект и один job, а ответ незавершённой A не считается успехом.

Этот повтор выполняется после **известного серверу успешного COMMIT**. Мы условно считаем, что клиент не получил ответ. Реальный сетевой обрыв здесь не вносится.

## S6. Разные ключи, сохранённый отказ и откат

Свежая база с debit. A: BEGIN; SELECT * FROM debit(7,'pay-a',1,80);. B: BEGIN; SELECT * FROM debit(7,'pay-b',1,80);. После наблюдения A COMMIT; затем B COMMIT. Второй результат declined с balance_after=20, без второго job.

Вне этих транзакций запустите fixtures/topup.sql один раз. Теперь баланс 100, но повтор pay-b по 80 всё ещё возвращает **сохранённый declined/20**, ничего не списывает и не создаёт job. В checks.sql пополнение учитывается отдельным журналом.

Для outbox-error-on.sql используйте ещё одну свежую базу. BEGIN; вызов debit; ожидаемый P0001; ROLLBACK. Из observer проверьте исходный баланс, отсутствие debit_operations и jobs. Отключите триггер. Повтор того же ключа теперь может успешно выполнить операцию.

## S7. 40001 и новое решение после отката

Свежая база с debit. A1:

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM wallets WHERE id=1;
```

B1 в autocommit:

```sql
SELECT * FROM debit(7,'winner',1,80);
```

A2: SELECT * FROM debit(7,'retry-me',1,30);. При эталоне получите 40001 на конфликтующей записи. SELECT 1 даст 25P02. ROLLBACK; новая полная попытка в Read Committed с тем же ключом даёт declined/20. После отката не переиспользуйте вычисления по прежним 100. COMMIT в приложении также должен находиться внутри обработки ошибок.

## S8. Дедлок и ограниченное ожидание

Свежая база, функции не требуются. Суммы не меняются, захватываются строки кошельков.

A1: BEGIN; UPDATE wallets SET balance=balance WHERE id=1;.

B1: BEGIN; UPDATE wallets SET balance=balance WHERE id=2;.

A2: UPDATE wallets SET balance=balance WHERE id=2;. Команда ждёт. Observer фиксирует блокера.

B2: UPDATE wallets SET balance=balance WHERE id=1;. PostgreSQL прервёт одного участника с 40P01. Выбор жертвы не задан. В прерванной сессии ROLLBACK; в другой COMMIT. Повторите целую операцию с новым BEGIN и одинаковым порядком id, объясните отличие ожидания от цикла.

Отдельная проба: A держит строку 1; B выполняет BEGIN; SET LOCAL lock_timeout='200ms'; UPDATE той же строки. Ожидается 55P03, затем 25P02 для SELECT 1. B делает ROLLBACK, A тоже завершает транзакцию. Намеренный таймаут здесь демонстрирует отказ ожидания, а не синхронизирует гонку.

## S9. Разные задания и устаревший воркер

Свежая база, однократно fixtures/queue.sql и ваша реализация очереди. A1:

```sql
BEGIN;
SELECT id AS job_id,claim_version AS ver FROM claim('worker-a',300)
\gset
\echo :job_id :ver
```

B1 в своей транзакции выполняет claim('worker-b',300). Он должен получить другой id, пока A ещё не завершила транзакцию. A2 COMMIT, B2 COMMIT. Не выполняйте внешнюю работу внутри этих транзакций.

В observer задайте id A и запустите expire.sql по README. B в новой короткой транзакции получает claim('worker-b',300): прежний job A, версия 2. COMMIT. A вызывает complete с версией 1 и worker-a: false. Неверный worker при версии 2 тоже false. B со своей версией 2 получает true, повтор complete даёт false.

Отдельно просрочьте аренду ещё running-задания и попробуйте complete до нового claim: false. Доработайте оставшиеся задания и проверьте 0 строк от claim на пустой доступной очереди. Для длительной рабочей обработки опишите продление/размер аренды, ограничение повторов и наблюдение отстающих заданий; здесь реализация heartbeat не требуется.

## S10. Окно внешнего действия

Используйте id реального job. provider_receipts моделирует отдельный сервис с атомарной дедупликацией. Каждый INSERT здесь выполняется отдельной autocommit-транзакцией, отдельно от claim/complete.

При ключах попыток:

```sql
INSERT INTO provider_receipts(delivery_key,job_id) VALUES('attempt-A',1);
INSERT INTO provider_receipts(delivery_key,job_id) VALUES('attempt-B',1);
SELECT count(*) FROM provider_receipts WHERE job_id=1;
```

Замените 1 на ваш job_id. Получите 2 внешних действия, несмотря на защиту версии jobs. Для стабильного ключа в **новом опыте**:

```sql
INSERT INTO provider_receipts(delivery_key,job_id) VALUES('notify-job-1',1)
ON CONFLICT DO NOTHING;
INSERT INTO provider_receipts(delivery_key,job_id) VALUES('notify-job-1',1)
ON CONFLICT DO NOTHING;
SELECT * FROM provider_receipts WHERE delivery_key='notify-job-1';
```

Замените job_id и ключ согласованно. Одна запись моделирует один эффект при двух попытках. Нужен также возврат исходного результата повтору, проверка параметров и достаточное время хранения ключа у провайдера. Этот SQL не проверяет реальную интеграцию по HTTP и её доступность.

# Самопроверка после собственной попытки

Сначала прочитайте [ключ](../answer-key.md). Эти функции показывают один допустимый вариант, **не являются автоматическим оценщиком произвольной реализации** и не стирают ваши SQL на компьютере. Для студента Python не нужен.

Из корня пакета создайте отдельную чистую базу:

```sh
docker --context colima-pgcourse06-live compose exec -T postgres createdb -U course hw06_reference
docker --context colima-pgcourse06-live compose exec -T postgres psql -X -U course -d hw06_reference -v ON_ERROR_STOP=1 -f /work/schema.sql -f /work/seed.sql -f /work/sanity.sql
docker --context colima-pgcourse06-live compose exec -T postgres psql -X -U course -d hw06_reference -v ON_ERROR_STOP=1 -f /work/self-check/01-reservations.sql -f /work/self-check/02-debit.sql -f /work/self-check/03-queue.sql
```

Для каждого независимого опыта создавайте новое имя базы и повторяйте загрузку, затем открывайте A/B/observer к ней. Нельзя выполнить все разделы последовательно на одних и тех же изменённых данных. Порядок [scenarios.md](../scenarios.md) и пометки «свежая база» сохраняются.

[01-reservations.sql](01-reservations.sql) требует Read Committed для guard и свежего count; другая изоляция отвергается с 25001. Другие корректные решения могут пользоваться счётчиком или Serializable с полным повтором. [02-debit.sql](02-debit.sql) основной протокол также демонстрирует в RC; в S7 используется отказ RR и новая полная попытка. [03-queue.sql](03-queue.sql) содержит claim и complete без внешнего HTTP.

Пройдите ошибочные и исправленные опыты. После завершения транзакций:

```sh
docker --context colima-pgcourse06-live compose exec -T postgres psql -X -U course -d hw06_reference -v ON_ERROR_STOP=1 -f /work/checks.sql
```

PASS подтверждает перечисленные правила **текущего** состояния. Сам по себе он не проверяет допуск отмены, сохранённый ответ, доступность очереди или внешнее действие. Для них нужны результаты вызовов и расписания. Отрицательные S1/S2 обязаны получить FAIL, затем повторяются в других свежих базах с защитой.

Эталоны намеренно не содержат внутреннего COMMIT: короткая транзакция и корректная обработка её результата остаются обязанностью вызывающего кода. Внешнюю работу выполнять после фиксации claim; хранить открытый lock на время HTTP не требуется.

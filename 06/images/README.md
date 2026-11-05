# Образ PostgreSQL

Стенд использует postgres:18.4-alpine. При наличии интернета Docker загрузит его при первом запуске. Для переноса без интернета заранее выполните на подключённом компьютере `docker --context colima-pgcourse06-live pull postgres:18.4-alpine`, затем `docker --context colima-pgcourse06-live save -o postgres-18.4-alpine.tar postgres:18.4-alpine`. На целевом компьютере: `docker --context colima-pgcourse06-live load -i postgres-18.4-alpine.tar`. Архив образа в Git-пакет не входит. Архитектура образа должна поддерживаться целевым компьютером.

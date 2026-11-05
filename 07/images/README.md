# Образ PostgreSQL

Используется postgres:18.4-alpine. Docker загрузит его при первом up. Других образов или пакетов для основной работы не требуется.

Для работы без интернета на подключённой машине: `docker pull postgres:18.4-alpine`, затем `docker save -o postgres-18.4-alpine.tar postgres:18.4-alpine`. На целевой машине: `docker load -i postgres-18.4-alpine.tar`. Архив образа не входит в Git; архитектура образа должна поддерживаться компьютером.

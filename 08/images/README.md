# Образ PostgreSQL

Compose использует официальный postgres:18.4-alpine. Первый запуск скачивает образ; остальная работа использует локальные данные. Порт хоста не нужен, psql уже внутри образа.

Для компьютера без сети образ можно подготовить заранее на совместимой архитектуре:

```sh
docker pull postgres:18.4-alpine
docker save -o postgres-18.4-alpine.tar postgres:18.4-alpine
```

На целевой машине:

```sh
docker load -i postgres-18.4-alpine.tar
docker compose up -d --wait
```

Архитектура образа должна соответствовать Docker-среде целевого компьютера. TAR передаётся отдельно и не включается в Git-пакет.

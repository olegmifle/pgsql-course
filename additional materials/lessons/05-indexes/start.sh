#!/bin/sh
set -eu

LIVE5_PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

compose() {
    docker compose --project-directory "$LIVE5_PACKAGE_DIR" \
        -f "$LIVE5_PACKAGE_DIR/compose.yaml" "$@"
}

if ! compose up -d --wait --wait-timeout 120; then
    printf '%s\n' 'Стенд не запущен. Причина указана в сообщении Docker выше. При input/output error проверьте свободное место и хранилище Docker.' >&2
    exit 1
fi

prepared=$(compose exec -T postgres psql -X -U course -d live5 \
    -v ON_ERROR_STOP=1 -Atqc "SELECT to_regclass('live5.orders') IS NOT NULL")

if [ "$prepared" = f ]; then
    compose exec -T postgres psql -X -U course -d live5 \
        -v ON_ERROR_STOP=1 -f /work/core/00_prepare.sql
else
    printf '%s\n' 'База live5 уже подготовлена. Существующие данные сохранены.'
fi

compose exec -T postgres psql -X -U course -d live5 -v ON_ERROR_STOP=1 -c \
    "SELECT current_database() AS database, current_user AS username,
            (SELECT count(*) FROM live5.orders) AS orders,
            (SELECT count(*) FROM live5.customers) AS customers,
            (SELECT count(*) FROM live5.events) AS events;"

printf '%s\n' 'Подключение: docker compose exec postgres psql -X -U course -d live5'

FROM postgres:18.4-alpine
RUN apk add --no-cache pgbouncer
COPY . /work
USER postgres
CMD ["sh", "/work/boot.sh"]

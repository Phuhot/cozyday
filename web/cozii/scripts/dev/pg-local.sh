#!/usr/bin/env bash
# Khởi động Postgres cục bộ để chạy test máy chủ (không dùng cho production).
# Dùng: scripts/dev/pg-local.sh [thư-mục-dữ-liệu]  → in ra TEST_DATABASE_URL
set -euo pipefail
DIR=${1:-${TMPDIR:-/tmp}/cozii-pg}
PORT=${PGPORT_COZII:-54329}
BIN=$(ls -d /usr/lib/postgresql/*/bin | sort -V | tail -1)
RUNAS=""
if [ "$(id -u)" = "0" ]; then RUNAS="runuser -u postgres --"; mkdir -p "$DIR"; chown postgres "$DIR"; fi
if [ ! -f "$DIR/PG_VERSION" ]; then
  $RUNAS "$BIN/initdb" -D "$DIR" -U postgres -A trust >/dev/null
fi
if ! $RUNAS "$BIN/pg_ctl" -D "$DIR" status >/dev/null 2>&1; then
  $RUNAS "$BIN/pg_ctl" -D "$DIR" -o "-p $PORT -k /tmp -c listen_addresses=127.0.0.1" -l "$DIR/log.txt" start >/dev/null
  sleep 1
fi
psql -h 127.0.0.1 -p $PORT -U postgres -tc "select 1 from pg_database where datname='cozii_test'" | grep -q 1 || psql -h 127.0.0.1 -p $PORT -U postgres -c "create database cozii_test" >/dev/null
echo "postgres://postgres@127.0.0.1:$PORT/cozii_test"

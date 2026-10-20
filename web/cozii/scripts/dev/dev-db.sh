#!/usr/bin/env bash
# Tạo cơ sở dữ liệu cozii_dev trên Postgres cục bộ để chạy thử chế độ online bằng `npm run dev:online`.
# CHỈ dùng trên máy: có thêm trigger tự tạo dòng auth.users giả cho tài khoản dev (Supabase thật đã có sẵn bảng này).
set -euo pipefail
cd "$(dirname "$0")/../.."
bash scripts/dev/pg-local.sh >/dev/null
PORT=${PGPORT_COZII:-54329}
P="psql -h 127.0.0.1 -p $PORT -U postgres -q -v ON_ERROR_STOP=1"
if ! $P -tc "select 1 from pg_database where datname='cozii_dev'" | grep -q 1; then
  $P -c "create database cozii_dev"
  $P -d cozii_dev -f supabase/tests/bootstrap-local.sql
  for f in supabase/migrations/*.sql; do $P -d cozii_dev -f "$f"; done
  $P -d cozii_dev <<'SQL'
create or replace function cozii.dev_stub_user() returns trigger language plpgsql as $$
begin
  insert into auth.users (id, is_anonymous) values (new.user_id, false) on conflict do nothing;
  return new;
end $$;
create trigger dev_stub_user before insert on cozii.accounts for each row execute function cozii.dev_stub_user();
SQL
fi
echo "postgres://postgres@127.0.0.1:$PORT/cozii_dev"

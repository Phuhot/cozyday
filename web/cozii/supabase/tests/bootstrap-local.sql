-- CHỈ DÙNG CHO TEST CỤC BỘ: giả lập phần Supabase có sẵn (roles anon/authenticated, bảng auth.users).
-- Không chạy file này trên Supabase thật.
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
end $$;
create schema if not exists auth;
create table if not exists auth.users (
  id uuid primary key,
  email text,
  is_anonymous boolean not null default false,
  created_at timestamptz not null default now()
);

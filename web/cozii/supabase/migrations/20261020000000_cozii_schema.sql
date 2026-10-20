-- Cozii! — lược đồ dữ liệu trên Supabase Postgres.
--
-- Nguyên tắc bảo mật:
-- * Mọi bảng nằm trong schema riêng `cozii`, KHÔNG nằm trong `public`, nên Data API (PostgREST) của Supabase không
--   đọc/ghi được các bảng này, kể cả khi có publishable/anon key.
-- * Bật Row Level Security trên mọi bảng và KHÔNG tạo policy nào cho `anon`/`authenticated` (= từ chối tất cả).
-- * Chỉ hàm máy chủ /api/cozii (chạy trên Vercel, dùng chuỗi kết nối bí mật DATABASE_URL) được đọc/ghi. Hàm đó xác minh
--   access token của người chơi với Supabase Auth, khóa dòng tài khoản (SELECT … FOR UPDATE), áp dụng luật chơi và
--   ghi kết quả trong MỘT giao dịch, kèm khóa chống trùng (request_id) cho mỗi thao tác.
-- * Người chơi không bao giờ ghi trực tiếp số xu, phần thưởng hay điểm số.

create schema if not exists cozii;
revoke all on schema cozii from public;
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'anon') then execute 'revoke all on schema cozii from anon'; end if;
  if exists (select 1 from pg_roles where rolname = 'authenticated') then execute 'revoke all on schema cozii from authenticated'; end if;
end $$;

-- Tài khoản: toàn bộ trạng thái game ở dạng JSON (cùng hình dạng với GameState trong src/core/state.ts),
-- cộng vài cột suy ra để truy vấn bạn bè / bảng xếp hạng. Ràng buộc CHECK chặn số dư âm ở tầng cơ sở dữ liệu.
create table if not exists cozii.accounts (
  user_id uuid primary key references auth.users (id) on delete cascade,
  state jsonb not null,
  friend_code text not null unique,
  display_name text not null default '',
  pet_name text not null default '',
  species text not null default 'cat',
  title text,
  is_anonymous boolean not null default true,
  unique_items integer not null default 0,
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint wallet_non_negative check (
    (state -> 'wallet' ->> 'coins')::int >= 0
    and (state -> 'wallet' ->> 'tickets')::int >= 0
    and (state -> 'wallet' ->> 'shards')::int >= 0
  ),
  constraint friend_code_format check (friend_code ~ '^[A-HJ-NP-Z2-9]{8}$')
);

-- Khóa chống trùng: mỗi (người chơi, mã yêu cầu) chỉ được xử lý một lần; gửi lại trả đúng kết quả cũ.
create table if not exists cozii.tx_log (
  user_id uuid not null references cozii.accounts (user_id) on delete cascade,
  request_id uuid not null,
  op text not null,
  response jsonb not null,
  created_at timestamptz not null default now(),
  primary key (user_id, request_id)
);
create index if not exists tx_log_recent on cozii.tx_log (user_id, created_at desc);

-- Bản nhà đã đăng (snapshot) — chỉ chứa dữ liệu cần để dựng phòng.
create table if not exists cozii.homes (
  user_id uuid primary key references cozii.accounts (user_id) on delete cascade,
  visibility text not null default 'private' check (visibility in ('private', 'friends', 'public')),
  snapshot jsonb,
  published_at timestamptz
);
create index if not exists homes_public on cozii.homes (published_at desc) where visibility = 'public' and snapshot is not null;

create table if not exists cozii.friend_requests (
  id uuid primary key default gen_random_uuid(),
  from_id uuid not null references cozii.accounts (user_id) on delete cascade,
  to_id uuid not null references cozii.accounts (user_id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (from_id, to_id),
  check (from_id <> to_id)
);
create index if not exists friend_requests_to on cozii.friend_requests (to_id);

-- Quan hệ bạn bè lưu hai chiều (A→B và B→A) để truy vấn đơn giản.
create table if not exists cozii.friendships (
  user_id uuid not null references cozii.accounts (user_id) on delete cascade,
  friend_id uuid not null references cozii.accounts (user_id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  check (user_id <> friend_id)
);

create table if not exists cozii.blocks (
  blocker uuid not null references cozii.accounts (user_id) on delete cascade,
  blocked uuid not null references cozii.accounts (user_id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker, blocked),
  check (blocker <> blocked)
);
create index if not exists blocks_blocked on cozii.blocks (blocked);

create table if not exists cozii.reports (
  id uuid primary key default gen_random_uuid(),
  reporter uuid not null references cozii.accounts (user_id) on delete cascade,
  target uuid not null references cozii.accounts (user_id) on delete cascade,
  reason text not null check (reason in ('name', 'spam', 'other')),
  details text not null default '' check (char_length(details) <= 300),
  status text not null default 'open' check (status in ('open', 'reviewed', 'dismissed')),
  created_at timestamptz not null default now()
);

-- Lượt thăm / lời khen / tưới giúp: khóa chính chặn thưởng lặp khi tải lại cùng một nhà.
create table if not exists cozii.visits (
  visitor uuid not null references cozii.accounts (user_id) on delete cascade,
  host uuid not null references cozii.accounts (user_id) on delete cascade,
  day date not null,
  rewarded boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (visitor, host, day)
);

create table if not exists cozii.compliments (
  visitor uuid not null references cozii.accounts (user_id) on delete cascade,
  host uuid not null references cozii.accounts (user_id) on delete cascade,
  day date not null,
  sticker text not null check (sticker in ('warm', 'cute', 'stay', 'garden', 'style', 'cozy')),
  created_at timestamptz not null default now(),
  primary key (visitor, host, day)
);
create index if not exists compliments_host on cozii.compliments (host, created_at desc);

create table if not exists cozii.help_waters (
  helper uuid not null references cozii.accounts (user_id) on delete cascade,
  host uuid not null references cozii.accounts (user_id) on delete cascade,
  plot integer not null check (plot between 0 and 11),
  planted_at bigint not null,
  day date not null,
  created_at timestamptz not null default now(),
  primary key (helper, host, plot, planted_at)
);
create index if not exists help_waters_host on cozii.help_waters (host, created_at desc);
create index if not exists help_waters_day on cozii.help_waters (helper, day);

-- Điểm xếp hạng: chỉ lượt máy chủ đã chạy lại (verified). Mỗi lượt chơi (run_id) chỉ có một dòng.
create table if not exists cozii.scores (
  run_id uuid primary key,
  user_id uuid not null references cozii.accounts (user_id) on delete cascade,
  game text not null,
  week text not null,
  weekly boolean not null default false,
  score integer not null check (score >= 0),
  meters integer not null default 0,
  stars integer not null default 0,
  verified boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists scores_board on cozii.scores (game, verified, weekly, week, score desc);
create index if not exists scores_user on cozii.scores (user_id, game);

-- RLS: bật cho mọi bảng, không policy cho anon/authenticated ⇒ từ chối mọi truy cập trực tiếp.
alter table cozii.accounts enable row level security;
alter table cozii.tx_log enable row level security;
alter table cozii.homes enable row level security;
alter table cozii.friend_requests enable row level security;
alter table cozii.friendships enable row level security;
alter table cozii.blocks enable row level security;
alter table cozii.reports enable row level security;
alter table cozii.visits enable row level security;
alter table cozii.compliments enable row level security;
alter table cozii.help_waters enable row level security;
alter table cozii.scores enable row level security;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'anon') then
    execute 'revoke all on all tables in schema cozii from anon';
  end if;
  if exists (select 1 from pg_roles where rolname = 'authenticated') then
    execute 'revoke all on all tables in schema cozii from authenticated';
  end if;
end $$;

-- Dọn tài khoản khách bỏ hoang (theo gợi ý của Supabase). Chạy tay hoặc bằng pg_cron nếu muốn:
-- delete from auth.users where is_anonymous is true and created_at < now() - interval '30 days';

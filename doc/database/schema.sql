-- スキーマ定義
-- 1. 拡張機能の有効化
create extension if not exists "uuid-ossp";

-- 2. ENUMタイプの作成
create type user_role as enum ('owner', 'staff', 'customer');

-- 3. テーブルの作成
-- 3.1 プロフィールテーブル
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  email text unique not null,
  full_name text,
  phone_number text,
  role user_role not null default 'customer',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3.2 店舗テーブル
create table stores (
  id uuid default uuid_generate_v4() primary key,
  owner_id uuid references profiles(id) on update cascade on delete restrict not null,
  name text not null,
  description text,
  phone_number text,
  address text,
  business_hours jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3.3 店舗スタッフテーブル
create table store_staff (
  id uuid default uuid_generate_v4() primary key,
  store_id uuid references stores(id) on update cascade on delete cascade not null,
  staff_id uuid references profiles(id) on update cascade on delete cascade not null,
  is_active boolean default true,
  permissions jsonb default '{"can_manage_reservations": true, "can_view_customer_data": true}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(store_id, staff_id)
);

-- 3.4 テーブル情報
create table tables (
  id uuid default uuid_generate_v4() primary key,
  store_id uuid references stores(id) on update cascade on delete cascade not null,
  name text not null,
  capacity int not null,
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3.5 予約テーブル
create table reservations (
  id uuid default uuid_generate_v4() primary key,
  store_id uuid references stores(id) on update cascade on delete restrict not null,
  table_id uuid references tables(id) on update cascade on delete restrict not null,
  customer_id uuid references profiles(id) on update cascade on delete restrict not null,
  reservation_date date not null,
  start_time time not null,
  end_time time not null,
  number_of_guests int not null,
  status text not null check (status in ('pending', 'confirmed', 'cancelled')),
  notes text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3.6 営業時間テーブル
create table business_hours (
  id uuid default uuid_generate_v4() primary key,
  store_id uuid references stores(id) on update cascade on delete cascade not null,
  day_of_week int not null check (day_of_week between 0 and 6),
  opening_time time not null,
  closing_time time not null,
  is_holiday boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(store_id, day_of_week)
);

-- 4. トリガー関数の作成
create or replace function update_updated_at_column()
returns trigger
security definer
set search_path = public
as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- 5. トリガーの設定
create trigger update_profiles_updated_at
  before update on profiles
  for each row
  execute function update_updated_at_column();

create trigger update_stores_updated_at
  before update on stores
  for each row
  execute function update_updated_at_column();

create trigger update_store_staff_updated_at
  before update on store_staff
  for each row
  execute function update_updated_at_column();

create trigger update_tables_updated_at
  before update on tables
  for each row
  execute function update_updated_at_column();

create trigger update_reservations_updated_at
  before update on reservations
  for each row
  execute function update_updated_at_column();

create trigger update_business_hours_updated_at
  before update on business_hours
  for each row
  execute function update_updated_at_column();

-- 6. インデックスの作成
create index idx_reservations_store_date on reservations(store_id, reservation_date);
create index idx_reservations_customer on reservations(customer_id);
create index idx_store_staff_store on store_staff(store_id);
create index idx_store_staff_staff on store_staff(staff_id);

-- 7. RLSの有効化
alter table profiles enable row level security;
alter table stores enable row level security;
alter table store_staff enable row level security;
alter table tables enable row level security;
alter table reservations enable row level security;
alter table business_hours enable row level security;

-- 8. RLSポリシーの設定
-- プロフィールのポリシー
create policy "プロフィールは本人とスタッフ/オーナーのみ参照可能"
  on profiles for select
  using (
    auth.uid() = id or
    exists (
      select 1 from store_staff ss
      join stores s on ss.store_id = s.id
      where (s.owner_id = auth.uid() or ss.staff_id = auth.uid())
    )
  );

-- 店舗のポリシー
create policy "店舗情報は認証ユーザーのみ参照可能"
  on stores for select
  using (auth.role() = 'authenticated');

create policy "店舗情報の更新はオーナーとアクティブなスタッフのみ可能"
  on stores for update
  using (
    auth.uid() = owner_id or
    exists (
      select 1 from store_staff
      where store_id = stores.id
      and staff_id = auth.uid()
      and is_active = true
    )
  );

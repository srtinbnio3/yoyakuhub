-- 初期データの投入
-- 1. プロフィールの作成
INSERT INTO profiles (id, email, full_name, phone_number, role)
VALUES 
  ('823b2ad6-9165-4a0d-b12f-76b1239212bd', 'iu11a15aaoi@gmail.com', 'システム管理者', '090-1111-1111', 'owner'),
  ('bda05511-144d-4ba1-8923-1ab7f6f3488e', 'staff1@example.com', 'テストスタッフ1', '090-2222-2222', 'staff'),
  ('081414ea-f46c-441c-8aa8-27cf1b8b4371', 'staff2@example.com', 'テストスタッフ2', '090-3333-3333', 'staff'),
  ('95e83727-2e53-4ad9-92d1-4e43b9e7d244', 'customer1@example.com', 'テスト顧客1', '090-4444-4444', 'customer'),
  ('1fa393be-b106-43de-9479-d66e819656ef', 'customer2@example.com', 'テスト顧客2', '090-5555-5555', 'customer');

-- 2. 店舗の作成
WITH inserted_stores AS (
  INSERT INTO stores (
    id,
    owner_id,
    name,
    description,
    phone_number,
    address,
    business_hours
  )
  VALUES 
    (
      uuid_generate_v4(),
      '823b2ad6-9165-4a0d-b12f-76b1239212bd',
      'テスト居酒屋',
      'テスト用の居酒屋です',
      '03-1111-2222',
      '東京都渋谷区テスト1-1-1',
      '{"default_hours":"17:00-23:00"}'
    ),
    (
      uuid_generate_v4(),
      '823b2ad6-9165-4a0d-b12f-76b1239212bd',
      'テストレストラン',
      'テスト用のレストランです',
      '03-2222-3333',
      '東京都新宿区テスト2-2-2',
      '{"default_hours":"11:00-22:00"}'
    )
  RETURNING *
)
SELECT id, name FROM inserted_stores;

-- 3. スタッフの割り当て
INSERT INTO store_staff (
  id,
  store_id,
  staff_id,
  is_active,
  permissions
)
SELECT
  uuid_generate_v4(),
  s.id,
  'bda05511-144d-4ba1-8923-1ab7f6f3488e'::uuid,
  true,
  '{"can_manage_reservations":true,"can_view_customer_data":true}'::jsonb
FROM stores s
WHERE s.name = 'テスト居酒屋'
UNION ALL
SELECT
  uuid_generate_v4(),
  s.id,
  '081414ea-f46c-441c-8aa8-27cf1b8b4371'::uuid,
  true,
  '{"can_manage_reservations":true,"can_view_customer_data":false}'::jsonb
FROM stores s
WHERE s.name = 'テスト居酒屋';

-- 4. テーブルの作成
WITH izakaya AS (
  SELECT id FROM stores WHERE name = 'テスト居酒屋'
),
restaurant AS (
  SELECT id FROM stores WHERE name = 'テストレストラン'
)
INSERT INTO tables (
  id,
  store_id,
  name,
  capacity,
  is_active
)
SELECT uuid_generate_v4(), izakaya.id, 'テーブルA', 4, true FROM izakaya
UNION ALL
SELECT uuid_generate_v4(), izakaya.id, 'テーブルB', 2, true FROM izakaya
UNION ALL
SELECT uuid_generate_v4(), izakaya.id, 'カウンターA', 1, true FROM izakaya
UNION ALL
SELECT uuid_generate_v4(), restaurant.id, 'テーブルA', 6, true FROM restaurant
UNION ALL
SELECT uuid_generate_v4(), restaurant.id, 'テーブルB', 4, true FROM restaurant;

-- 5. 営業時間の設定
WITH izakaya AS (
  SELECT id FROM stores WHERE name = 'テスト居酒屋'
)
INSERT INTO business_hours (
  id,
  store_id,
  day_of_week,
  opening_time,
  closing_time,
  is_holiday
)
SELECT
  uuid_generate_v4(),
  izakaya.id,
  day_of_week,
  '17:00'::time,
  '23:00'::time,
  CASE WHEN day_of_week = 0 THEN true ELSE false END
FROM izakaya, generate_series(0, 6) AS day_of_week;

-- 6. 予約データの作成
WITH izakaya AS (
  SELECT id FROM stores WHERE name = 'テスト居酒屋'
),
table_a AS (
  SELECT id FROM tables WHERE name = 'テーブルA' AND store_id = (SELECT id FROM izakaya)
),
table_b AS (
  SELECT id FROM tables WHERE name = 'テーブルB' AND store_id = (SELECT id FROM izakaya)
)
INSERT INTO reservations (
  id,
  store_id,
  table_id,
  customer_id,
  reservation_date,
  start_time,
  end_time,
  number_of_guests,
  status,
  notes
)
SELECT
  uuid_generate_v4(),
  izakaya.id,
  table_a.id,
  '95e83727-2e53-4ad9-92d1-4e43b9e7d244'::uuid,
  '2025-02-15'::date,
  '18:00'::time,
  '20:00'::time,
  3,
  'confirmed',
  'アレルギー：えび'
FROM izakaya, table_a
UNION ALL
SELECT
  uuid_generate_v4(),
  izakaya.id,
  table_b.id,
  '1fa393be-b106-43de-9479-d66e819656ef'::uuid,
  '2025-02-15'::date,
  '19:00'::time,
  '21:00'::time,
  2,
  'confirmed',
  null
FROM izakaya, table_b;

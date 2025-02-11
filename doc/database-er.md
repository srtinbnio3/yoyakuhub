# YoyakuHub Database ER Diagram

```mermaid
erDiagram
    profiles ||--o{ stores : "owns"
    profiles ||--o{ store_staff : "works_at"
    profiles ||--o{ reservations : "makes"
    stores ||--|{ store_staff : "has"
    stores ||--|{ tables : "has"
    stores ||--|{ business_hours : "has"
    tables ||--o{ reservations : "used_in"

    profiles {
        uuid id PK
        text email
        text full_name
        text phone_number
        user_role role
        timestamp created_at
        timestamp updated_at
    }

    stores {
        uuid id PK
        uuid owner_id FK
        text name
        text description
        text phone_number
        text address
        jsonb business_hours
        timestamp created_at
        timestamp updated_at
    }

    store_staff {
        uuid id PK
        uuid store_id FK
        uuid staff_id FK
        boolean is_active
        jsonb permissions
        timestamp created_at
        timestamp updated_at
    }

    tables {
        uuid id PK
        uuid store_id FK
        text name
        int capacity
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    reservations {
        uuid id PK
        uuid store_id FK
        uuid table_id FK
        uuid customer_id FK
        date reservation_date
        time start_time
        time end_time
        int number_of_guests
        text status
        text notes
        timestamp created_at
        timestamp updated_at
    }

    business_hours {
        uuid id PK
        uuid store_id FK
        int day_of_week
        time opening_time
        time closing_time
        boolean is_holiday
        timestamp created_at
        timestamp updated_at
    }
```

## リレーションシップの説明

1. `profiles` (ユーザープロファイル)
   - 店舗オーナー、スタッフ、顧客の情報を管理
   - `role`で役割を区別（owner/staff/customer）

2. `stores` (店舗)
   - `owner_id`で店舗オーナーとの関連を管理
   - 1人のオーナーは複数の店舗を持つことが可能

3. `store_staff` (店舗スタッフ)
   - 店舗とスタッフの中間テーブル
   - スタッフの権限管理も行う

4. `tables` (テーブル情報)
   - 各店舗の座席情報を管理
   - `capacity`で収容人数を管理

5. `reservations` (予約)
   - 予約情報を管理
   - 店舗、テーブル、顧客との関連を持つ

6. `business_hours` (営業時間)
   - 店舗ごとの営業時間を管理
   - 曜日ごとに異なる営業時間の設定が可能
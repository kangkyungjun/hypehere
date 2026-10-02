-- admin_user_snapshot: 유저/활성 지표 (DAU/WAU/MAU) — 서버 롤업 단독 소유.
-- prod에 테이블이 이미 있어도/없어도 안전: 없으면 생성, 있으면 누락 컬럼만 추가.
-- 실행: python run_migration.py 006_add_active_user_metrics.sql
--
-- 롤업은 활성 컬럼(dau/wau/mau/stickiness 등)만 컬럼단위 upsert.
-- total/new 등 누적 유저수 컬럼은 별도 소유(있으면 그대로 유지, 없으면 NULL).

CREATE TABLE IF NOT EXISTS analytics.admin_user_snapshot (
    date date PRIMARY KEY
);

ALTER TABLE analytics.admin_user_snapshot
    ADD COLUMN IF NOT EXISTS total_users     int,
    ADD COLUMN IF NOT EXISTS android_users   int,
    ADD COLUMN IF NOT EXISTS ios_users       int,
    ADD COLUMN IF NOT EXISTS new_users_today int,
    ADD COLUMN IF NOT EXISTS dau             int,
    ADD COLUMN IF NOT EXISTS dau_android     int,
    ADD COLUMN IF NOT EXISTS dau_ios         int,
    ADD COLUMN IF NOT EXISTS dau_unknown     int,   -- X-Platform 없는 first-touch
    ADD COLUMN IF NOT EXISTS wau             int,
    ADD COLUMN IF NOT EXISTS wau_android     int,
    ADD COLUMN IF NOT EXISTS wau_ios         int,
    ADD COLUMN IF NOT EXISTS mau             int,
    ADD COLUMN IF NOT EXISTS stickiness      double precision;

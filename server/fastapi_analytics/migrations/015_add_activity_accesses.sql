-- 관리자 패널 유저별 접속 지표(총/이번달 × 횟수/일수 + 마지막 접속).
--
-- 배경:
--   user_activity_daily 는 하루 1유저 1행이고 raw 는 90일 후 purge 된다.
--   따라서 "총 접속/총 접속일수"를 raw 만으로 세면 사실상 "최근 90일"이 되어 오해를 준다.
--   → 세션 횟수 카운터(accesses)를 raw 에 추가하고, purge 와 무관한 영구 누적 테이블을 둔다.
--
-- 정의:
--   accesses           : 그 날의 세션(포그라운드 핑) 횟수. 신규일 1, 이후 핑마다 +1.
--   user_activity_totals: 유저별 영구 누적(90일 purge 영향 없음).
--     total_accesses    = 모든 세션 누적, total_active_days = 활동한 고유일 누적,
--     last_access       = 마지막 접속일.
--
-- 비파괴: 컬럼/테이블 추가 + 기존값 백필만. 실행: python run_migration.py 015_add_activity_accesses.sql

ALTER TABLE analytics.user_activity_daily
    ADD COLUMN IF NOT EXISTS accesses integer NOT NULL DEFAULT 1;

CREATE TABLE IF NOT EXISTS analytics.user_activity_totals (
    user_id           integer     PRIMARY KEY,
    total_accesses    bigint      NOT NULL DEFAULT 0,  -- 모든 세션(핑) 누적
    total_active_days integer     NOT NULL DEFAULT 0,  -- 활동한 고유일 누적
    last_access       date,                            -- 마지막 접속일
    updated_at        timestamptz NOT NULL DEFAULT now()
);

-- 기존 raw(≤90일)로 최초 백필 — 이미 행이 있으면 유지(멱등).
INSERT INTO analytics.user_activity_totals (user_id, total_accesses, total_active_days, last_access)
SELECT user_id, COALESCE(SUM(accesses), 0), COUNT(*), MAX(date)
FROM analytics.user_activity_daily
GROUP BY user_id
ON CONFLICT (user_id) DO NOTHING;

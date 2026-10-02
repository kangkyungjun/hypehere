-- DAU/WAU 수집 원천 테이블 — 하루 1유저 1행 (first-touch 플랫폼).
-- analytics 스키마. 비파괴 — 신규 테이블만 추가, 기존 무영향.
-- 실행: python run_migration.py 004_add_user_activity.sql
--
-- 정의:
--   PK(date, user_id) + ON CONFLICT DO NOTHING → 하루 1유저 1행(멱등).
--   platform = 그날 첫 핑 기기(first-touch). NULL = unknown(X-Platform 헤더 없음).
--   '하루' 경계는 대시보드 전체와 동일 TZ(현재 KST, /ping 핸들러와 롤업이 같은 기준 사용).
-- 보존: raw 90일 후 삭제(롤업 이후에 삭제 — 순서 고정). 집계 snapshot은 영구(별도).
-- 인덱스: 추가 없음 — PK(date,user_id) 선두컬럼 date가 날짜범위 스캔을 커버.

CREATE TABLE IF NOT EXISTS analytics.user_activity_daily (
    date     date    NOT NULL,
    user_id  integer NOT NULL,
    platform text,                         -- 'ios' | 'android' | NULL(unknown)
    PRIMARY KEY (date, user_id)
);

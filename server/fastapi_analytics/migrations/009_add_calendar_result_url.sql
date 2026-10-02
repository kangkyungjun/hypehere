-- 캘린더 "결과 팔로업" — market_calendar.result_url 컬럼 추가.
-- 비파괴(컬럼 추가만), 기본 NULL. 맥미니가 ingest 시 큐레이션 URL을 함께 보내고,
-- 서버는 GET /api/v1/events/calendar 응답에서 과거 이벤트에만 노출. 큐레이션 없으면
-- 읽기 시점에 Google 검색 폴백 URL을 계산해 내려준다(컬럼 갱신 X).
--
-- 실행: python run_migration.py 009_add_calendar_result_url.sql

ALTER TABLE analytics.market_calendar
    ADD COLUMN IF NOT EXISTS result_url TEXT;

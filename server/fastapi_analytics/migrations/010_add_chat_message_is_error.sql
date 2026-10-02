-- AI 채팅 메시지에 에러 플래그 추가.
-- 맥미니가 LLM 실패/timeout 시 폴백 메시지를 assistant 턴으로 보내되 is_error=TRUE 로
-- 마킹해 앱이 점3개 멈추고 에러 스타일로 표시할 수 있게 한다.
-- 비파괴 — 컬럼 추가 + 기본값 FALSE.
--
-- 실행: python run_migration.py 010_add_chat_message_is_error.sql

ALTER TABLE analytics.chat_messages
    ADD COLUMN IF NOT EXISTS is_error BOOLEAN NOT NULL DEFAULT FALSE;

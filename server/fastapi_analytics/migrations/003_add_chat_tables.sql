-- AI 멀티턴 채팅 대화 저장소 (SoT=서버)
-- analytics 스키마. 비파괴 — 신규 테이블만 추가, 기존 무영향.
-- 실행: python run_migration.py 003_add_chat_tables.sql

CREATE TABLE IF NOT EXISTS analytics.conversations (
    id          VARCHAR(64) PRIMARY KEY,        -- 앱 생성 id (c_...)
    user_id     INTEGER NOT NULL,
    title       VARCHAR(200),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_conversations_user
    ON analytics.conversations (user_id, updated_at DESC);

CREATE TABLE IF NOT EXISTS analytics.chat_messages (
    id              BIGSERIAL PRIMARY KEY,
    conversation_id VARCHAR(64) NOT NULL,
    user_id         INTEGER NOT NULL,
    role            VARCHAR(16) NOT NULL,        -- user / assistant
    content         TEXT NOT NULL,
    turn_index      INTEGER,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_conv
    ON analytics.chat_messages (conversation_id, turn_index);

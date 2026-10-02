-- Macro 지표 변동성 AI 설명 캐시.
-- 같은 indicator_code + lang + hour_bucket 으로 1시간 캐시 (LLM 비용 절감).
-- 채팅처럼 채팅 메시지 테이블에는 안 쌓이고 별도 캐시로만 보관.

CREATE TABLE IF NOT EXISTS analytics.macro_explanations (
    indicator_code  VARCHAR(32)  NOT NULL,
    lang            VARCHAR(8)   NOT NULL,
    hour_bucket     TIMESTAMP    NOT NULL,        -- date_trunc('hour', now()) at insert
    content         TEXT         NOT NULL,
    is_error        BOOLEAN      NOT NULL DEFAULT FALSE,
    request_id      BIGINT,                       -- analysis_requests.id (참조용, FK 없음)
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (indicator_code, lang, hour_bucket)
);

CREATE INDEX IF NOT EXISTS ix_macro_explanations_request_id
    ON analytics.macro_explanations (request_id);

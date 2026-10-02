-- ============================================================
-- 실시간 포트폴리오 AI 분석 파이프라인: 분석 요청 큐 테이블
-- 2026-03-13
-- ============================================================

-- 분석 요청 큐: Flutter가 포트폴리오 변경 시 INSERT, 맥미니가 폴링하여 처리
CREATE TABLE IF NOT EXISTS analytics.analysis_requests (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    request_type VARCHAR(30) NOT NULL,          -- PORTFOLIO_CHANGE / DAILY_BATCH
    status VARCHAR(20) DEFAULT 'PENDING',       -- PENDING → PROCESSING → COMPLETED / FAILED
    trigger_data JSONB,                         -- {"ticker":"AAPL","action":"ADD_HOLDING","shares":10,"avg_price":178.5}
    result_summary VARCHAR(500),                -- 완료 후 한줄 요약
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,                       -- 맥미니가 처리 시작한 시각
    completed_at TIMESTAMP                      -- 맥미니가 처리 완료한 시각
);

-- 인덱스: 맥미니 폴링 (status=PENDING)
CREATE INDEX IF NOT EXISTS idx_analysis_requests_status
    ON analytics.analysis_requests (status);

-- 인덱스: 유저별 최근 요청 조회 (Flutter 폴링)
CREATE INDEX IF NOT EXISTS idx_analysis_requests_user_id
    ON analytics.analysis_requests (user_id, created_at DESC);

-- 인덱스: 오래된 요청 정리
CREATE INDEX IF NOT EXISTS idx_analysis_requests_created_at
    ON analytics.analysis_requests (created_at);

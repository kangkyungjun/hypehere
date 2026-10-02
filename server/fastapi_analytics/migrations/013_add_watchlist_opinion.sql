-- 013_add_watchlist_opinion.sql
-- 관심종목 개인화 AI 의견 캐시 (맥미니 생성 → 서버 저장 → 앱 조회).
-- 기존 종목 상세 공통 코멘트(ticker_ai_analysis)와 별개: 유저 관심 맥락 반영 개인화 의견.
-- UPSERT 키: (user_id, ticker, date) — 유저·종목·거래일별 1건.

CREATE TABLE IF NOT EXISTS analytics.watchlist_opinion (
    user_id          INTEGER      NOT NULL,
    ticker           VARCHAR(10)  NOT NULL,
    date             DATE         NOT NULL,
    opinion          TEXT,                    -- 다국어 ||| 5세그먼트 (ko|||en|||zh|||ja|||es)
    stance           VARCHAR(8),              -- BUY | HOLD | SELL (선택)
    confidence       DOUBLE PRECISION,        -- 0.0 ~ 1.0 (선택)
    target_buy_price DOUBLE PRECISION,        -- 참고 에코 (선택)
    request_id       BIGINT,                  -- 분석 요청 추적 (선택)
    created_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, ticker, date)
);

-- 유저별 최신 의견 조회용 (읽기 API: 종목별 최신 date 1건).
CREATE INDEX IF NOT EXISTS idx_watchlist_opinion_user_latest
    ON analytics.watchlist_opinion (user_id, ticker, date DESC);

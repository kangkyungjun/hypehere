-- intraday 차트(시간봉) 데이터 — "오늘 시장이 어떻게 움직였나" 그래프용.
-- 최근 거래일(들)의 1시간봉 OHLCV. 맥미니 deep_bot_intraday가 yfinance interval=60m로 수집
-- → POST /api/v1/internal/ingest/intraday 로 upsert(같은 거래일은 통째 교체).
-- 거래일당 정규장 ~7봉, 500종목 × 7 ≈ 3500행으로 가벼움.
--
-- 시간은 TIMESTAMPTZ로 저장(맥미니가 보낸 ET offset → UTC 자동 정규화).
-- 응답 시 America/New_York로 변환해 ISO-8601 ET offset으로 내려준다(앱이 표시 시 변환).
--
-- 실행: python run_migration.py 011_add_ticker_intraday.sql

CREATE TABLE IF NOT EXISTS analytics.ticker_intraday (
    ticker     VARCHAR(10) NOT NULL,
    datetime   TIMESTAMPTZ NOT NULL,          -- 봉 시작 시각(ET offset 입력, UTC 저장)
    interval   VARCHAR(8) NOT NULL DEFAULT '1h', -- 1h(v1) / 추후 5m/15m 확장 여지
    open       NUMERIC(12,4),
    high       NUMERIC(12,4),
    low        NUMERIC(12,4),
    close      NUMERIC(12,4),
    volume     BIGINT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, datetime)
);

CREATE INDEX IF NOT EXISTS ix_intraday_ticker_dt
    ON analytics.ticker_intraday (ticker, datetime DESC);

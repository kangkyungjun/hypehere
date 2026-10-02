-- Migration: Add analyst target price fields and analyst ratings table
-- Date: 2026-02-15
-- Description: Support yfinance consensus + finvizfinance institutional ratings

-- 1) ticker_targets 확장 (yfinance 컨센서스)
ALTER TABLE analytics.ticker_targets ADD COLUMN IF NOT EXISTS analyst_target_mean REAL;
ALTER TABLE analytics.ticker_targets ADD COLUMN IF NOT EXISTS analyst_target_high REAL;
ALTER TABLE analytics.ticker_targets ADD COLUMN IF NOT EXISTS analyst_target_low REAL;
ALTER TABLE analytics.ticker_targets ADD COLUMN IF NOT EXISTS analyst_count INTEGER;
ALTER TABLE analytics.ticker_targets ADD COLUMN IF NOT EXISTS recommendation VARCHAR(20);

-- 2) 신규 테이블: 기관별 애널리스트 ratings
CREATE TABLE IF NOT EXISTS analytics.ticker_analyst_ratings (
    ticker VARCHAR(10),
    date DATE,
    rating_date DATE,
    status VARCHAR(30),
    firm VARCHAR(100),
    rating VARCHAR(50),
    target_from REAL,
    target_to REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (date, ticker, firm, rating_date)
);

-- 3) 인덱스
CREATE INDEX IF NOT EXISTS idx_analyst_ratings_ticker_date
    ON analytics.ticker_analyst_ratings (ticker, date);

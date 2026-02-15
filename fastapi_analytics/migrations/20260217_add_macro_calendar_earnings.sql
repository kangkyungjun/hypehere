-- Migration: Add macro indicators, ticker calendar, and ticker earnings history tables
-- Date: 2026-02-17

-- 거시경제 지표 (Mac mini dict 형식에 맞춤)
CREATE TABLE IF NOT EXISTS analytics.macro_indicators (
    date              DATE NOT NULL,
    indicator_code    VARCHAR(30) NOT NULL,
    indicator_name    VARCHAR(100),
    observation_date  DATE,
    value             REAL NOT NULL,
    previous_value    REAL,
    change_pct        REAL,
    source            VARCHAR(30) DEFAULT 'FRED',
    updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (date, indicator_code)
);
CREATE INDEX IF NOT EXISTS idx_macro_date ON analytics.macro_indicators (date DESC);

-- 종목별 일정 (yfinance calendar 기반)
CREATE TABLE IF NOT EXISTS analytics.ticker_calendar (
    ticker              VARCHAR(10) NOT NULL,
    date                DATE NOT NULL,
    next_earnings_date  DATE,
    ex_dividend_date    DATE,
    dividend_date       DATE,
    earnings_high       REAL,
    earnings_low        REAL,
    earnings_avg        REAL,
    revenue_high        REAL,
    revenue_low         REAL,
    revenue_avg         REAL,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, date)
);

-- 종목별 실적 이력 (yfinance get_earnings_dates 기반)
CREATE TABLE IF NOT EXISTS analytics.ticker_earnings_history (
    ticker          VARCHAR(10) NOT NULL,
    earnings_date   DATE NOT NULL,
    eps_estimate    REAL,
    reported_eps    REAL,
    surprise_pct    REAL,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, earnings_date)
);

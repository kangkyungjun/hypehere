-- ============================================
-- Fundamentals Tables Migration
-- Date: 2026-02-16
-- Purpose: Company profile, key metrics, financials, dividends
-- ============================================

-- 1) Company Profile (종목당 1행, 비시계열)
CREATE TABLE IF NOT EXISTS analytics.company_profile (
    ticker VARCHAR(10) PRIMARY KEY,
    long_name VARCHAR(255),
    industry VARCHAR(100),
    website VARCHAR(255),
    country VARCHAR(50),
    employees INTEGER,
    summary TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_company_profile_industry ON analytics.company_profile(industry);

-- 2) Key Metrics (일별 시계열)
CREATE TABLE IF NOT EXISTS analytics.ticker_key_metrics (
    date DATE NOT NULL,
    ticker VARCHAR(10) NOT NULL,
    market_cap DECIMAL(20,2),
    pe DECIMAL(10,2),
    forward_pe DECIMAL(10,2),
    peg DECIMAL(10,4),
    pb DECIMAL(10,2),
    ps DECIMAL(10,2),
    ev_revenue DECIMAL(10,2),
    ev_ebitda DECIMAL(10,2),
    profit_margin DECIMAL(10,6),
    operating_margin DECIMAL(10,6),
    gross_margin DECIMAL(10,6),
    roe DECIMAL(10,6),
    roa DECIMAL(10,6),
    debt_to_equity DECIMAL(10,2),
    current_ratio DECIMAL(10,4),
    beta DECIMAL(10,4),
    dividend_yield DECIMAL(10,6),
    payout_ratio DECIMAL(10,6),
    earnings_growth DECIMAL(10,6),
    revenue_growth DECIMAL(10,6),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (date, ticker)
);

CREATE INDEX IF NOT EXISTS idx_ticker_key_metrics_ticker ON analytics.ticker_key_metrics(ticker);

-- 3) Financials (종목당 1행, JSONB)
CREATE TABLE IF NOT EXISTS analytics.ticker_financials (
    ticker VARCHAR(10) PRIMARY KEY,
    latest_quarter VARCHAR(10),
    income JSONB,
    balance_sheet JSONB,
    cash_flow JSONB,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4) Dividends (종목 + ex_date별)
CREATE TABLE IF NOT EXISTS analytics.ticker_dividends (
    ticker VARCHAR(10) NOT NULL,
    ex_date DATE NOT NULL,
    amount DECIMAL(10,4),
    PRIMARY KEY (ticker, ex_date)
);

CREATE INDEX IF NOT EXISTS idx_ticker_dividends_date ON analytics.ticker_dividends(ex_date);

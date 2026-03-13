-- ============================================================
-- Phase 1: AI 투자 브레인 — 6 New Tables
-- Migration: 20260308_phase1_ai_brain_tables.sql
-- ============================================================

-- 1) 유저 보유/관심 종목
CREATE TABLE IF NOT EXISTS analytics.user_portfolios (
    user_id INTEGER NOT NULL,
    ticker VARCHAR(10) NOT NULL,
    type VARCHAR(10) NOT NULL DEFAULT 'WATCHLIST',  -- HOLDING | WATCHLIST
    shares FLOAT,
    avg_price FLOAT,
    notes VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, ticker)
);

CREATE INDEX IF NOT EXISTS idx_user_portfolios_user ON analytics.user_portfolios (user_id);
CREATE INDEX IF NOT EXISTS idx_user_portfolios_ticker ON analytics.user_portfolios (ticker);

-- 2) 매수/매도 거래 이력
CREATE TABLE IF NOT EXISTS analytics.user_transactions (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    ticker VARCHAR(10) NOT NULL,
    type VARCHAR(4) NOT NULL,  -- BUY | SELL
    shares FLOAT NOT NULL,
    price FLOAT NOT NULL,
    date DATE NOT NULL,
    notes VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_transactions_user ON analytics.user_transactions (user_id);
CREATE INDEX IF NOT EXISTS idx_user_transactions_ticker ON analytics.user_transactions (ticker);

-- 3) 종목별 AI 의견
CREATE TABLE IF NOT EXISTS analytics.portfolio_advice (
    user_id INTEGER NOT NULL,
    ticker VARCHAR(10) NOT NULL,
    date DATE NOT NULL,
    signal VARCHAR(10),
    confidence FLOAT,
    summary VARCHAR(2000),
    reasons JSONB,
    target_action VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, ticker, date)
);

CREATE INDEX IF NOT EXISTS idx_portfolio_advice_user ON analytics.portfolio_advice (user_id);

-- 4) 유저별 일일 P&L 요약
CREATE TABLE IF NOT EXISTS analytics.portfolio_summary (
    user_id INTEGER NOT NULL,
    date DATE NOT NULL,
    total_value FLOAT,
    total_cost FLOAT,
    total_pnl FLOAT,
    total_pnl_pct FLOAT,
    day_pnl FLOAT,
    day_pnl_pct FLOAT,
    holdings_detail JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_portfolio_summary_user ON analytics.portfolio_summary (user_id);

-- 5) 유저 알림
CREATE TABLE IF NOT EXISTS analytics.user_alerts (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    ticker VARCHAR(10),
    alert_type VARCHAR(30) NOT NULL,
    title VARCHAR(500) NOT NULL,
    message VARCHAR(2000),
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_alerts_user ON analytics.user_alerts (user_id);
CREATE INDEX IF NOT EXISTS idx_user_alerts_ticker ON analytics.user_alerts (ticker);

-- 6) 일별 환율 (USD/KRW)
CREATE TABLE IF NOT EXISTS analytics.exchange_rates (
    date DATE PRIMARY KEY,
    usd_krw FLOAT NOT NULL,
    source VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7) AI 시그널 (종목별 매매 신호)
CREATE TABLE IF NOT EXISTS analytics.ai_signals (
    ticker VARCHAR(10) NOT NULL,
    date DATE NOT NULL,
    signal VARCHAR(15) NOT NULL,       -- STRONG_BUY/BUY/HOLD/SELL/STRONG_SELL
    confidence FLOAT,
    price_at_signal FLOAT,
    target_price FLOAT,
    stop_loss_price FLOAT,
    reasoning VARCHAR(2000),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, date)
);

CREATE INDEX IF NOT EXISTS idx_ai_signals_date ON analytics.ai_signals (date);

-- 8) AI 메시지 (브리핑, 리뷰, Q&A)
CREATE TABLE IF NOT EXISTS analytics.ai_messages (
    id BIGSERIAL PRIMARY KEY,
    type VARCHAR(30) NOT NULL,         -- daily_briefing / portfolio_review / stock_qa
    date DATE NOT NULL,
    user_id INTEGER,                    -- NULL = 전체 브리핑
    messages JSONB NOT NULL,            -- [{role, content}]
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ai_messages_user ON analytics.ai_messages (user_id);
CREATE INDEX IF NOT EXISTS idx_ai_messages_date ON analytics.ai_messages (date);
CREATE INDEX IF NOT EXISTS idx_ai_messages_type ON analytics.ai_messages (type);

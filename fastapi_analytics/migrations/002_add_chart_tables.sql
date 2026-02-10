-- ============================================================
-- Migration: Add 5 chart-serving tables for Flutter app
-- Created: 2026-02-06
-- Purpose: Store indicators, targets, trendlines, institutions, shorts
-- ============================================================

-- ========================================
-- Table 1: ticker_indicators
-- Technical indicators (RSI, MACD, Bollinger Bands)
-- ========================================
CREATE TABLE IF NOT EXISTS analytics.ticker_indicators (
    ticker VARCHAR(10) NOT NULL,
    date DATE NOT NULL,

    -- RSI (Relative Strength Index)
    rsi REAL,

    -- MACD (Moving Average Convergence Divergence)
    macd REAL,
    macd_signal REAL,
    macd_hist REAL,

    -- Bollinger Bands
    bb_width REAL,
    bb_upper REAL,
    bb_lower REAL,
    bb_middle REAL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, date)
);

CREATE INDEX IF NOT EXISTS idx_ticker_indicators_date
    ON analytics.ticker_indicators (date);

CREATE INDEX IF NOT EXISTS idx_ticker_indicators_ticker_date
    ON analytics.ticker_indicators (ticker, date);

COMMENT ON TABLE analytics.ticker_indicators IS 'Technical indicators for chart overlay (RSI, MACD, BB)';
COMMENT ON COLUMN analytics.ticker_indicators.rsi IS 'Relative Strength Index (0-100)';
COMMENT ON COLUMN analytics.ticker_indicators.macd IS 'MACD line value';
COMMENT ON COLUMN analytics.ticker_indicators.macd_signal IS 'MACD signal line';
COMMENT ON COLUMN analytics.ticker_indicators.macd_hist IS 'MACD histogram (macd - signal)';


-- ========================================
-- Table 2: ticker_targets
-- Target price and stop loss levels
-- ========================================
CREATE TABLE IF NOT EXISTS analytics.ticker_targets (
    ticker VARCHAR(10) NOT NULL,
    date DATE NOT NULL,

    target_price REAL,
    stop_loss REAL,

    -- Risk/Reward ratio (calculated)
    risk_reward_ratio REAL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, date)
);

CREATE INDEX IF NOT EXISTS idx_ticker_targets_date
    ON analytics.ticker_targets (date);

CREATE INDEX IF NOT EXISTS idx_ticker_targets_ticker_date
    ON analytics.ticker_targets (ticker, date);

COMMENT ON TABLE analytics.ticker_targets IS 'Target price and stop loss for chart horizontal lines';
COMMENT ON COLUMN analytics.ticker_targets.target_price IS 'AI-calculated target price';
COMMENT ON COLUMN analytics.ticker_targets.stop_loss IS 'AI-calculated stop loss level';
COMMENT ON COLUMN analytics.ticker_targets.risk_reward_ratio IS 'R/R ratio: (target - current) / (current - stop)';


-- ========================================
-- Table 3: ticker_trendlines
-- Trendline coefficients for chart rendering
-- ========================================
CREATE TABLE IF NOT EXISTS analytics.ticker_trendlines (
    ticker VARCHAR(10) NOT NULL,
    date DATE NOT NULL,

    -- High trendline: y = high_slope * x + high_intercept
    high_slope REAL,
    high_intercept REAL,
    high_r_squared REAL,  -- R² coefficient (trendline reliability)

    -- Low trendline: y = low_slope * x + low_intercept
    low_slope REAL,
    low_intercept REAL,
    low_r_squared REAL,

    -- Trend calculation period
    trend_period_days INT DEFAULT 30,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, date)
);

CREATE INDEX IF NOT EXISTS idx_ticker_trendlines_date
    ON analytics.ticker_trendlines (date);

CREATE INDEX IF NOT EXISTS idx_ticker_trendlines_ticker_date
    ON analytics.ticker_trendlines (ticker, date);

COMMENT ON TABLE analytics.ticker_trendlines IS 'Linear trendline coefficients for chart overlay';
COMMENT ON COLUMN analytics.ticker_trendlines.high_slope IS 'Slope of high price trendline';
COMMENT ON COLUMN analytics.ticker_trendlines.high_r_squared IS 'R² value (0-1, higher = more reliable)';


-- ========================================
-- Table 4: ticker_institutions
-- Institutional and foreign ownership changes
-- ========================================
CREATE TABLE IF NOT EXISTS analytics.ticker_institutions (
    ticker VARCHAR(10) NOT NULL,
    date DATE NOT NULL,

    -- Current ownership (percentage or absolute shares)
    inst_ownership REAL,  -- Institutional ownership %
    foreign_ownership REAL,  -- Foreign ownership %

    -- Changes over time windows (percentage points)
    inst_chg_1d REAL,   -- 1-day change
    inst_chg_5d REAL,   -- 5-day change
    inst_chg_15d REAL,  -- 15-day change
    inst_chg_30d REAL,  -- 30-day change

    foreign_chg_1d REAL,
    foreign_chg_5d REAL,
    foreign_chg_15d REAL,
    foreign_chg_30d REAL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, date)
);

CREATE INDEX IF NOT EXISTS idx_ticker_institutions_date
    ON analytics.ticker_institutions (date);

CREATE INDEX IF NOT EXISTS idx_ticker_institutions_ticker_date
    ON analytics.ticker_institutions (ticker, date);

COMMENT ON TABLE analytics.ticker_institutions IS 'Institutional and foreign ownership data';
COMMENT ON COLUMN analytics.ticker_institutions.inst_ownership IS 'Current institutional ownership %';
COMMENT ON COLUMN analytics.ticker_institutions.inst_chg_1d IS '1-day institutional ownership change (pp)';


-- ========================================
-- Table 5: ticker_shorts
-- Short selling data
-- ========================================
CREATE TABLE IF NOT EXISTS analytics.ticker_shorts (
    ticker VARCHAR(10) NOT NULL,
    date DATE NOT NULL,

    -- Short metrics
    short_ratio REAL,       -- Days to cover (short interest / avg daily volume)
    short_percent_float REAL,  -- Short % of float
    short_percent_shares REAL, -- Short % of shares outstanding

    -- Short interest (absolute shares shorted)
    short_interest BIGINT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, date)
);

CREATE INDEX IF NOT EXISTS idx_ticker_shorts_date
    ON analytics.ticker_shorts (date);

CREATE INDEX IF NOT EXISTS idx_ticker_shorts_ticker_date
    ON analytics.ticker_shorts (ticker, date);

COMMENT ON TABLE analytics.ticker_shorts IS 'Short selling metrics';
COMMENT ON COLUMN analytics.ticker_shorts.short_ratio IS 'Days to cover (short interest / avg volume)';
COMMENT ON COLUMN analytics.ticker_shorts.short_percent_float IS 'Short % of float (higher = more bearish sentiment)';

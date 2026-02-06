-- ============================================================
-- Migration: Add ticker_prices table for OHLCV data
-- Created: 2026-02-06
-- Purpose: Store daily price data for charting
-- ============================================================

-- Create ticker_prices table
CREATE TABLE IF NOT EXISTS analytics.ticker_prices (
    ticker VARCHAR(10) NOT NULL,
    date DATE NOT NULL,
    open REAL,
    high REAL,
    low REAL,
    close REAL,
    volume BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, date)
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_ticker_prices_date
    ON analytics.ticker_prices (date);

CREATE INDEX IF NOT EXISTS idx_ticker_prices_ticker_date
    ON analytics.ticker_prices (ticker, date);

-- Add comments
COMMENT ON TABLE analytics.ticker_prices IS 'Daily OHLCV price data for charting';
COMMENT ON COLUMN analytics.ticker_prices.ticker IS 'Stock symbol (e.g. AAPL)';
COMMENT ON COLUMN analytics.ticker_prices.date IS 'Price data date';
COMMENT ON COLUMN analytics.ticker_prices.open IS 'Opening price';
COMMENT ON COLUMN analytics.ticker_prices.high IS 'Highest price of the day';
COMMENT ON COLUMN analytics.ticker_prices.low IS 'Lowest price of the day';
COMMENT ON COLUMN analytics.ticker_prices.close IS 'Closing price';
COMMENT ON COLUMN analytics.ticker_prices.volume IS 'Trading volume';

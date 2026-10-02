-- Migration: Add treemap fields for S&P 500 sector treemap chart
-- Date: 2026-02-15
-- Description: Add sector/sub_industry to tickers, change_pct/trading_value to ticker_prices

-- 1) Add sector metadata to tickers (quasi-static, rarely changes)
ALTER TABLE analytics.tickers ADD COLUMN IF NOT EXISTS sector VARCHAR(100);
ALTER TABLE analytics.tickers ADD COLUMN IF NOT EXISTS sub_industry VARCHAR(200);

-- 2) Add daily market data to ticker_prices (changes daily)
ALTER TABLE analytics.ticker_prices ADD COLUMN IF NOT EXISTS change_pct REAL;
ALTER TABLE analytics.ticker_prices ADD COLUMN IF NOT EXISTS trading_value REAL;

-- 3) Index for treemap GROUP BY sector queries
CREATE INDEX IF NOT EXISTS idx_tickers_sector ON analytics.tickers (sector);

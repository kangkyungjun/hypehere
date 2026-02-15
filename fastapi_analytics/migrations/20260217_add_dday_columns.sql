-- Migration: Add D-Day countdown columns to ticker_calendar + earnings_week_events table
-- Date: 2026-02-17

-- 1) ticker_calendar: 3 new columns for earnings D-Day countdown
ALTER TABLE analytics.ticker_calendar ADD COLUMN IF NOT EXISTS next_earnings_date_end DATE;
ALTER TABLE analytics.ticker_calendar ADD COLUMN IF NOT EXISTS earnings_confirmed BOOLEAN DEFAULT FALSE;
ALTER TABLE analytics.ticker_calendar ADD COLUMN IF NOT EXISTS d_day INTEGER;

-- 2) earnings_week_events: weekly earnings schedule for Flutter calendar screen
CREATE TABLE IF NOT EXISTS analytics.earnings_week_events (
    ticker          VARCHAR(10) NOT NULL,
    earnings_date   DATE NOT NULL,
    earnings_time   VARCHAR(10),        -- BMO/AMC/TAS/Unknown
    eps_estimate    REAL,
    revenue_estimate REAL,
    market_cap      REAL,
    sector          VARCHAR(50),
    name_en         VARCHAR(100),
    name_ko         VARCHAR(100),
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, earnings_date)
);

CREATE INDEX IF NOT EXISTS idx_earnings_week_date ON analytics.earnings_week_events(earnings_date);

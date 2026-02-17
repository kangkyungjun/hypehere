-- Migration: Recreate earnings_week_events with new schema
-- Date: 2026-02-17
-- Reason: Mac mini payload format changed (nested earnings_estimate, new fields)

DROP TABLE IF EXISTS analytics.earnings_week_events;

CREATE TABLE analytics.earnings_week_events (
    ticker              VARCHAR(10) NOT NULL,
    earnings_date       DATE NOT NULL,
    week                VARCHAR(10),
    name_ko             VARCHAR(100),
    name_en             VARCHAR(100),
    earnings_date_end   DATE,
    earnings_confirmed  BOOLEAN DEFAULT FALSE,
    d_day               INTEGER,
    eps_estimate_high   REAL,
    eps_estimate_low    REAL,
    eps_estimate_avg    REAL,
    revenue_estimate    REAL,
    prev_surprise_pct   REAL,
    score               REAL,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, earnings_date)
);

CREATE INDEX IF NOT EXISTS idx_earnings_week_date
    ON analytics.earnings_week_events(earnings_date);
CREATE INDEX IF NOT EXISTS idx_earnings_week_week
    ON analytics.earnings_week_events(week);

-- Migration: Add trendline y-values to ticker_trendlines table
-- Date: 2026-02-11
-- Purpose: Store pre-calculated trendline y-values for each date to fix Flutter rendering issue
--
-- Background:
-- Mac mini calculates trendlines using Python array indices (0..250)
-- Flutter cannot reconstruct trendlines from slope/intercept alone without index context
-- Solution: Store pre-calculated y-values for each date as JSONB arrays

-- Add columns to store trendline y-values as JSONB
ALTER TABLE analytics.ticker_trendlines
ADD COLUMN IF NOT EXISTS high_values JSONB,
ADD COLUMN IF NOT EXISTS low_values JSONB;

-- Add comments for documentation
COMMENT ON COLUMN analytics.ticker_trendlines.high_values IS 'Pre-calculated high trendline y-values: [{"date": "2024-10-20", "y": 148.20}, ...]';
COMMENT ON COLUMN analytics.ticker_trendlines.low_values IS 'Pre-calculated low trendline y-values: [{"date": "2024-10-20", "y": 130.15}, ...]';

-- Create index for better query performance (optional, but recommended)
CREATE INDEX IF NOT EXISTS idx_ticker_trendlines_high_values ON analytics.ticker_trendlines USING GIN (high_values);
CREATE INDEX IF NOT EXISTS idx_ticker_trendlines_low_values ON analytics.ticker_trendlines USING GIN (low_values);

-- Migration: Add ticker_ai_analysis table and modify ticker_scores.signal length
-- Date: 2026-02-07
-- Description: Support nested payload from Mac mini with AI analysis data

-- 1. Create ticker_ai_analysis table
CREATE TABLE IF NOT EXISTS analytics.ticker_ai_analysis (
    ticker VARCHAR(10) NOT NULL,
    date DATE NOT NULL,
    probability FLOAT NOT NULL,
    summary VARCHAR(200) NOT NULL,
    bullish_reasons JSONB,
    bearish_reasons JSONB,
    final_comment VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, date)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_ticker_ai_analysis_ticker ON analytics.ticker_ai_analysis(ticker);
CREATE INDEX IF NOT EXISTS idx_ticker_ai_analysis_date ON analytics.ticker_ai_analysis(date);

-- 2. Modify ticker_scores.signal column length (10 → 20)
-- PostgreSQL doesn't support conditional ALTER COLUMN, so we check first
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'analytics'
        AND table_name = 'ticker_scores'
        AND column_name = 'signal'
        AND character_maximum_length = 10
    ) THEN
        ALTER TABLE analytics.ticker_scores
        ALTER COLUMN signal TYPE VARCHAR(20);

        RAISE NOTICE 'ticker_scores.signal column length changed from VARCHAR(10) to VARCHAR(20)';
    ELSE
        RAISE NOTICE 'ticker_scores.signal column already VARCHAR(20) or different length, skipping';
    END IF;
END $$;

-- Verification
SELECT
    'ticker_ai_analysis' as table_name,
    COUNT(*) as row_count
FROM analytics.ticker_ai_analysis
UNION ALL
SELECT
    'ticker_scores' as table_name,
    COUNT(*) as row_count
FROM analytics.ticker_scores;

-- Display column info for verification
SELECT
    column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'analytics'
AND table_name = 'ticker_scores'
AND column_name = 'signal';

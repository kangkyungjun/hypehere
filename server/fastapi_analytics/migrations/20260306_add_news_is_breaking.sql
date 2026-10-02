-- Add is_breaking column for breaking news detection
ALTER TABLE analytics.ticker_news
    ADD COLUMN IF NOT EXISTS is_breaking BOOLEAN DEFAULT FALSE;

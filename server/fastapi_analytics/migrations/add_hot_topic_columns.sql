-- Migration: Add hot topic columns to analytics.ticker_news
-- Date: 2026-04-08
-- Description: Support hot topic news for toast overlay in Flutter app

ALTER TABLE analytics.ticker_news ADD COLUMN IF NOT EXISTS is_hot_topic BOOLEAN DEFAULT FALSE;
ALTER TABLE analytics.ticker_news ADD COLUMN IF NOT EXISTS hot_topic_category VARCHAR(30);
ALTER TABLE analytics.ticker_news ADD COLUMN IF NOT EXISTS hot_topic_priority INTEGER;

-- Verify
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'analytics' AND table_name = 'ticker_news'
  AND column_name IN ('is_hot_topic', 'hot_topic_category', 'hot_topic_priority');

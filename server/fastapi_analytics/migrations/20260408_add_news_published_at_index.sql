-- 20260408: Add index on ticker_news.published_at for mention-bubble query
-- The mention-bubble endpoint filters WHERE published_at >= cutoff,
-- which causes a full table scan without this index.

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ticker_news_published_at
ON analytics.ticker_news (published_at DESC);

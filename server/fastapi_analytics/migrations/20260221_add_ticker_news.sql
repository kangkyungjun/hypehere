-- Migration: Add ticker_news table for news ingest & serving
-- Date: 2026-02-21

CREATE TABLE IF NOT EXISTS analytics.ticker_news (
    id              BIGSERIAL PRIMARY KEY,
    date            DATE NOT NULL,
    ticker          VARCHAR(10) NOT NULL,
    title           VARCHAR(512) NOT NULL,
    title_hash      VARCHAR(32) NOT NULL,
    source          VARCHAR(100),
    source_url      VARCHAR(2048),
    published_at    TIMESTAMP NOT NULL,
    ai_summary      VARCHAR(200) NOT NULL,
    sentiment_score SMALLINT NOT NULL,
    sentiment_grade VARCHAR(10) NOT NULL,
    sentiment_label VARCHAR(10) NOT NULL,
    future_event    JSONB,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE (ticker, date, title_hash)
);

CREATE INDEX IF NOT EXISTS idx_ticker_news_ticker_date ON analytics.ticker_news (ticker, date DESC);
CREATE INDEX IF NOT EXISTS idx_ticker_news_date ON analytics.ticker_news (date DESC);
CREATE INDEX IF NOT EXISTS idx_ticker_news_sentiment ON analytics.ticker_news (ticker, sentiment_grade);

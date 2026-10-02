-- Migration: Add stock_classifications table (Peter Lynch 6-category)
-- Run on AWS RDS PostgreSQL

CREATE TABLE IF NOT EXISTS analytics.stock_classifications (
    date DATE NOT NULL,
    ticker VARCHAR(10) NOT NULL,
    category VARCHAR(20) NOT NULL,
    category_ko VARCHAR(20) NOT NULL,
    category_en VARCHAR(20) NOT NULL,
    confidence FLOAT DEFAULT 0.0,
    reason_ko TEXT,
    reason_en TEXT,
    metrics_json TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (date, ticker)
);

CREATE INDEX IF NOT EXISTS idx_classification_category ON analytics.stock_classifications(category);
CREATE INDEX IF NOT EXISTS idx_classification_ticker ON analytics.stock_classifications(ticker);

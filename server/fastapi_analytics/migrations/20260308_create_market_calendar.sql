CREATE TABLE IF NOT EXISTS analytics.market_calendar (
    id VARCHAR(16) PRIMARY KEY,
    event_date DATE NOT NULL,
    event_type VARCHAR(30) NOT NULL,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    ticker VARCHAR(10),
    importance VARCHAR(10) DEFAULT 'medium',
    source VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_market_calendar_date ON analytics.market_calendar(event_date);
CREATE INDEX IF NOT EXISTS idx_market_calendar_type ON analytics.market_calendar(event_type);

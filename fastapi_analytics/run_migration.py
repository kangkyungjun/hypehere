#!/usr/bin/env python3
"""
Run database migration: Create ticker_prices table
"""
import sys
import os

# Add app directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from sqlalchemy import create_engine, text
from app.config import settings

def run_migration():
    """Execute migration SQL"""
    engine = create_engine(settings.DATABASE_ANALYTICS_URL)

    migration_sql = """
    -- Create ticker_prices table
    CREATE TABLE IF NOT EXISTS analytics.ticker_prices (
        ticker VARCHAR(10) NOT NULL,
        date DATE NOT NULL,
        open REAL,
        high REAL,
        low REAL,
        close REAL,
        volume BIGINT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (ticker, date)
    );

    -- Create indexes
    CREATE INDEX IF NOT EXISTS idx_ticker_prices_date
        ON analytics.ticker_prices (date);

    CREATE INDEX IF NOT EXISTS idx_ticker_prices_ticker_date
        ON analytics.ticker_prices (ticker, date);

    -- Add comments
    COMMENT ON TABLE analytics.ticker_prices IS 'Daily OHLCV price data for charting';
    COMMENT ON COLUMN analytics.ticker_prices.ticker IS 'Stock symbol (e.g. AAPL)';
    COMMENT ON COLUMN analytics.ticker_prices.date IS 'Price data date';
    COMMENT ON COLUMN analytics.ticker_prices.open IS 'Opening price';
    COMMENT ON COLUMN analytics.ticker_prices.high IS 'Highest price of the day';
    COMMENT ON COLUMN analytics.ticker_prices.low IS 'Lowest price of the day';
    COMMENT ON COLUMN analytics.ticker_prices.close IS 'Closing price';
    COMMENT ON COLUMN analytics.ticker_prices.volume IS 'Trading volume';
    """

    with engine.connect() as conn:
        conn.execute(text(migration_sql))
        conn.commit()
        print("✅ Migration completed successfully!")
        print("   - Table: analytics.ticker_prices created")
        print("   - Indexes: created")

if __name__ == "__main__":
    run_migration()

-- 시장 주요 지수 테이블 (SPY, QQQ, DIA)
-- 2026-02-19

CREATE TABLE IF NOT EXISTS analytics.market_indices (
    date DATE NOT NULL,
    code VARCHAR(10) NOT NULL,
    name VARCHAR(50) NOT NULL,
    open DOUBLE PRECISION,
    high DOUBLE PRECISION,
    low DOUBLE PRECISION,
    close DOUBLE PRECISION,
    volume BIGINT,
    prev_close DOUBLE PRECISION,
    change DOUBLE PRECISION,
    change_pct DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (date, code)
);

CREATE TABLE IF NOT EXISTS analytics.market_index_chart (
    code VARCHAR(10) NOT NULL,
    date DATE NOT NULL,
    close DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (code, date)
);

CREATE INDEX IF NOT EXISTS idx_market_indices_date ON analytics.market_indices(date);
CREATE INDEX IF NOT EXISTS idx_market_index_chart_code ON analytics.market_index_chart(code, date);

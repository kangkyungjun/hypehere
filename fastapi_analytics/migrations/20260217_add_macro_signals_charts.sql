-- Migration: Add macro signals (시장레이더/머니프린팅) columns + chart time-series table
-- Date: 2026-02-17

-- 기존 macro_indicators에 시장레이더/머니프린팅 컬럼 추가
ALTER TABLE analytics.macro_indicators ADD COLUMN IF NOT EXISTS risk_level VARCHAR(20);
ALTER TABLE analytics.macro_indicators ADD COLUMN IF NOT EXISTS signal_message TEXT;
ALTER TABLE analytics.macro_indicators ADD COLUMN IF NOT EXISTS liquidity_status VARCHAR(20);

-- 매크로 차트 시계열 테이블 (t10y2y, m2_growth 등)
CREATE TABLE IF NOT EXISTS analytics.macro_chart_data (
    series_id   VARCHAR(30) NOT NULL,
    date        DATE NOT NULL,
    value       REAL NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (series_id, date)
);
CREATE INDEX IF NOT EXISTS idx_macro_chart_series ON analytics.macro_chart_data(series_id, date DESC);

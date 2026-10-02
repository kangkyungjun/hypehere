-- Migration: Add defense lines, recommendations, institutional holders tables + insider_ownership column
-- Date: 2026-02-17

-- 이동평균 방어선 (period별 MA 가격)
CREATE TABLE IF NOT EXISTS analytics.ticker_defense_lines (
    ticker          VARCHAR(10) NOT NULL,
    date            DATE NOT NULL,
    period          INTEGER NOT NULL,
    price           REAL NOT NULL,
    label           VARCHAR(20),
    distance_pct    REAL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, date, period)
);
CREATE INDEX IF NOT EXISTS idx_defense_lines_ticker ON analytics.ticker_defense_lines(ticker, date DESC);

-- 애널리스트 의견분포 (strong_buy ~ strong_sell)
CREATE TABLE IF NOT EXISTS analytics.ticker_recommendations (
    ticker          VARCHAR(10) NOT NULL,
    date            DATE NOT NULL,
    strong_buy      INTEGER DEFAULT 0,
    buy             INTEGER DEFAULT 0,
    hold            INTEGER DEFAULT 0,
    sell            INTEGER DEFAULT 0,
    strong_sell     INTEGER DEFAULT 0,
    consensus_score REAL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, date)
);

-- 개별 기관투자자 보유 현황
CREATE TABLE IF NOT EXISTS analytics.ticker_institutional_holders (
    ticker      VARCHAR(10) NOT NULL,
    date        DATE NOT NULL,
    holder      VARCHAR(100) NOT NULL,
    pct_held    REAL,
    pct_change  REAL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, date, holder)
);
CREATE INDEX IF NOT EXISTS idx_inst_holders_ticker ON analytics.ticker_institutional_holders(ticker, date DESC);

-- 기존 ticker_institutions에 insider_ownership 컬럼 추가
ALTER TABLE analytics.ticker_institutions ADD COLUMN IF NOT EXISTS insider_ownership REAL;

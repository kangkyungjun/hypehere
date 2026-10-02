-- Stock membership tagging (SP500, DOW30, NASDAQ100)
-- Migration: 20260220_add_stock_membership.sql

CREATE TABLE IF NOT EXISTS analytics.stock_membership (
    ticker      VARCHAR(10) NOT NULL,
    index_code  VARCHAR(20) NOT NULL,
    PRIMARY KEY (ticker, index_code)
);

CREATE INDEX IF NOT EXISTS idx_membership_index ON analytics.stock_membership (index_code);

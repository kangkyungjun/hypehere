-- FCM 알림 발송 로그 테이블
-- 중복 방지 (같은 date + ticker + signal_type) + 감사 로그

CREATE TABLE IF NOT EXISTS analytics.notification_log (
    id              BIGSERIAL PRIMARY KEY,
    date            DATE NOT NULL,
    ticker          VARCHAR(50) NOT NULL,
    signal_type     VARCHAR(30) NOT NULL,
    score           FLOAT,
    recipients_count INTEGER NOT NULL DEFAULT 0,
    success_count   INTEGER NOT NULL DEFAULT 0,
    failure_count   INTEGER NOT NULL DEFAULT 0,
    error_detail    TEXT,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_nlog_date ON analytics.notification_log (date DESC);
CREATE INDEX IF NOT EXISTS idx_nlog_ticker_date ON analytics.notification_log (ticker, date DESC);
CREATE INDEX IF NOT EXISTS idx_nlog_dedup ON analytics.notification_log (date, ticker, signal_type);

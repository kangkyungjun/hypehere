-- Account withdrawal reasons table
-- Stores user withdrawal reasons from Flutter app for admin review

CREATE TABLE IF NOT EXISTS analytics.account_withdrawals (
    id BIGSERIAL PRIMARY KEY,
    user_email VARCHAR(255) NOT NULL,
    user_nickname VARCHAR(100),
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

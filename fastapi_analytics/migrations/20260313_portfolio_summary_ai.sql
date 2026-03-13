-- Add AI summary, recommendations, and realized P&L fields to portfolio_summary
-- Date: 2026-03-13

ALTER TABLE analytics.portfolio_summary
    ADD COLUMN IF NOT EXISTS ai_summary VARCHAR(2000),
    ADD COLUMN IF NOT EXISTS ai_recommendations JSONB,
    ADD COLUMN IF NOT EXISTS realized_pnl FLOAT;

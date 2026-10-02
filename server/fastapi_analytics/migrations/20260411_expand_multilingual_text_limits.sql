-- Migration: Expand multilingual packed text field limits
-- Date: 2026-04-11
-- Reason: 다국어 packed 텍스트(ko|||en|||zh|||ja|||es)가 길어져서 422 에러 발생

-- 1. ticker_ai_analysis: summary 1000→4000, final_comment 2500→4000
ALTER TABLE analytics.ticker_ai_analysis ALTER COLUMN summary TYPE VARCHAR(4000);
ALTER TABLE analytics.ticker_ai_analysis ALTER COLUMN final_comment TYPE VARCHAR(4000);

-- 2. ticker_news: title 512→1000, sentiment_label 100→500
ALTER TABLE analytics.ticker_news ALTER COLUMN title TYPE VARCHAR(1000);
ALTER TABLE analytics.ticker_news ALTER COLUMN sentiment_label TYPE VARCHAR(500);

-- 3. portfolio_advice: summary 2000→4000, target_action 500→2000
ALTER TABLE analytics.portfolio_advice ALTER COLUMN summary TYPE VARCHAR(4000);
ALTER TABLE analytics.portfolio_advice ALTER COLUMN target_action TYPE VARCHAR(2000);

-- 4. portfolio_summary: ai_summary 2000→4000
ALTER TABLE analytics.portfolio_summary ALTER COLUMN ai_summary TYPE VARCHAR(4000);

-- 5. user_alerts: title 500→2000, message 2000→4000
ALTER TABLE analytics.user_alerts ALTER COLUMN title TYPE VARCHAR(2000);
ALTER TABLE analytics.user_alerts ALTER COLUMN message TYPE VARCHAR(4000);

-- 6. market_calendar: title 500→2000
ALTER TABLE analytics.market_calendar ALTER COLUMN title TYPE VARCHAR(2000);

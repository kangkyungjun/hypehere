-- Add expert analysis columns to ticker_ai_analysis table
-- Expert analysis = LLM-generated 5-language commentary with prediction and key factors
-- confidence maps to existing probability column (no new column needed)

ALTER TABLE analytics.ticker_ai_analysis ADD COLUMN IF NOT EXISTS analysis_ko TEXT;
ALTER TABLE analytics.ticker_ai_analysis ADD COLUMN IF NOT EXISTS analysis_en TEXT;
ALTER TABLE analytics.ticker_ai_analysis ADD COLUMN IF NOT EXISTS analysis_zh TEXT;
ALTER TABLE analytics.ticker_ai_analysis ADD COLUMN IF NOT EXISTS analysis_ja TEXT;
ALTER TABLE analytics.ticker_ai_analysis ADD COLUMN IF NOT EXISTS analysis_es TEXT;
ALTER TABLE analytics.ticker_ai_analysis ADD COLUMN IF NOT EXISTS expert_prediction VARCHAR(20);
ALTER TABLE analytics.ticker_ai_analysis ADD COLUMN IF NOT EXISTS expert_key_factors JSONB;

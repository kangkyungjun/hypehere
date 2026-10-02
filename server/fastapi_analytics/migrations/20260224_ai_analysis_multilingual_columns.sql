-- Widen AI analysis columns for multilingual ||| packed strings
-- summary: 200 → 1000 (5 languages × ~100 chars + separators)
-- final_comment: 500 → 2500 (5 languages × ~300 chars + separators)

ALTER TABLE analytics.ticker_ai_analysis
    ALTER COLUMN summary TYPE VARCHAR(1000),
    ALTER COLUMN final_comment TYPE VARCHAR(2500);

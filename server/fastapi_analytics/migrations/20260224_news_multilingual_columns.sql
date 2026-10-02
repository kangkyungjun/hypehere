-- Widen news columns for multilingual ||| packed strings
-- ai_summary: 200 → 1000 (5 languages × ~100 chars + separators)
-- sentiment_label: 10 → 100 (5 languages packed, e.g. "호재|||Bullish|||利好|||好材料|||Alcista")

ALTER TABLE analytics.ticker_news
    ALTER COLUMN ai_summary TYPE VARCHAR(1000),
    ALTER COLUMN sentiment_label TYPE VARCHAR(100);

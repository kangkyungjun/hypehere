-- Widen defense line label for multilingual packed strings (ko|||en|||zh|||ja|||es)
-- Previous: VARCHAR(20), insufficient for packed format
-- See also: 52fd07a (news), 373a5c1 (AI analysis) for same pattern

ALTER TABLE analytics.ticker_defense_lines ALTER COLUMN label TYPE VARCHAR(200);

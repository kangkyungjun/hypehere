-- Add MFI (Money Flow Index) column to ticker_indicators
-- MFI is a volume-weighted RSI, range 0-100
-- Existing rows will have NULL (graceful fallback on Flutter side)
ALTER TABLE analytics.ticker_indicators ADD COLUMN IF NOT EXISTS mfi REAL;

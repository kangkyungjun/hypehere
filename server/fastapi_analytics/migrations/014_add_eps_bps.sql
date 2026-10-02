-- 014_add_eps_bps.sql
-- 개별 기업 투자지표에 EPS(주당순이익)·BPS(주당순자산) 추가.
-- 맥미니가 fundamentals.metrics.{eps,bps} 로 전송 → 앱 개별기업창 투자지표 섹션 표시.
-- 전부 nullable 추가 컬럼이라 하위호환(기존 행은 NULL).

ALTER TABLE analytics.ticker_key_metrics ADD COLUMN IF NOT EXISTS eps DOUBLE PRECISION;
ALTER TABLE analytics.ticker_key_metrics ADD COLUMN IF NOT EXISTS bps DOUBLE PRECISION;

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains **MarketLens FastAPI** — the stock market analytics API backend for the MarketLens Flutter app.

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Nginx Reverse Proxy                 │
│  /api/v1/         → FastAPI (Uvicorn, Port 8001) │
│  /api/marketlens/ → Django (Gunicorn, Port 8002) │
└─────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
  ┌──────────────┐         ┌──────────────────┐
  │  FastAPI      │         │  MarketLens      │
  │  Stock API    │         │  Django Community │
  │  (this repo)  │         │  (separate repo) │
  └──────────────┘         └──────────────────┘
         │                          │
         └────────────┬─────────────┘
                      ▼
          ┌────────────────────────┐
          │  PostgreSQL RDS        │
          │  analytics.* → FastAPI │
          │  public.*    → Django  │
          └────────────────────────┘
                      ▲
                      │
          ┌────────────────────────┐
          │  Mac mini (Daily Cron) │
          │  Data collection       │
          │  AI analysis           │
          │  → POST to FastAPI     │
          │    /internal/ingest/   │
          └────────────────────────┘
                      │
                      ▼
          ┌────────────────────────┐
          │  Flutter App           │
          │  (MarketLens)          │
          │  ← GET from FastAPI    │
          └────────────────────────┘
```

**CRITICAL**: FastAPI does NOT fetch external data. All data collection and AI analysis happens on Mac mini only. FastAPI is receive + serve.

## Development Setup

### FastAPI (this repo)
```bash
cd fastapi_analytics
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8001     # Dev server
# Swagger UI: http://localhost:8001/docs
# ReDoc: http://localhost:8001/redoc
```

### Analytics Schema Migrations (Manual SQL)
```bash
# FastAPI uses raw SQL migrations, NOT Django ORM
psql -h <rds-host> -U <user> -d hypehere -f fastapi_analytics/migrations/<filename>.sql
```

### Testing & Linting

No test framework or linting tools are configured.

### Deployment
```bash
# SCP files to AWS, then restart service
scp -i ~/Downloads/hypehere-key.pem <files> ubuntu@43.201.45.60:/tmp/
ssh -i ~/Downloads/hypehere-key.pem ubuntu@43.201.45.60
  sudo cp /tmp/<files> /home/django/fastapi_analytics/
  sudo systemctl restart fastapi-analytics
```

Systemd services on AWS:
```bash
sudo systemctl restart fastapi-analytics     # FastAPI (Uvicorn:8001)
sudo systemctl restart marketlens-django     # MarketLens Django (Gunicorn:8002)
sudo systemctl restart nginx
```

## Database Schema

**Single PostgreSQL RDS, dual schema**:
- `analytics.*` → SQLAlchemy (MarketLens stock data) — this repo
- `public.*` → Django ORM (MarketLens community + auth) — separate repo

```bash
# FastAPI .env (in fastapi_analytics/)
DATABASE_ANALYTICS_URL=postgresql://user:pass@host:5432/hypehere?options=-c%20search_path=analytics
ANALYTICS_API_KEY=<key-for-mac-mini-ingest>
```

---

## FastAPI Details

### API Endpoints

**Public (Flutter app consumes)**:
| Endpoint | Purpose |
|----------|---------|
| `GET /api/v1/scores/{ticker}` | Score history for ticker |
| `GET /api/v1/scores/top` | Top scoring tickers by date |
| `GET /api/v1/scores/insights` | Top/bottom performers dashboard |
| `GET /api/v1/tickers/search` | Search by symbol or name (EN/KO) |
| `GET /api/v1/tickers/{ticker}` | Ticker metadata |
| `GET /api/v1/prices/{ticker}` | OHLCV price history |
| `GET /api/v1/charts/{ticker}` | **Complete chart data** (16 data sources in one response) |
| `GET /api/v1/market/treemap` | S&P 500 sector treemap |
| `GET /api/v1/macro/indicators` | Macro economic indicators (FRED) |
| `GET /api/v1/earnings/...` | Earnings calendar data |

**Internal (Mac mini → AWS, `X-API-Key` header required)**:
| Endpoint | Purpose |
|----------|---------|
| `POST /api/v1/internal/ingest/scores` | Ingest all ticker data |
| `POST /api/v1/internal/ingest/macro` | Ingest macro indicators |

### Database Models (analytics.* schema, 17 tables)

**Core**: TickerScore, Ticker, TickerPrice
**Technical**: TickerIndicator (RSI/MACD/BB/MFI), TickerTrendline, TickerTarget
**Institutional**: TickerInstitution, TickerShort, TickerAnalystRating
**AI**: TickerAIAnalysis (probability, bullish/bearish reasons)
**Fundamentals**: CompanyProfile, TickerKeyMetrics, TickerFinancials, TickerDividend
**Macro**: MacroIndicator (FRED: FEDFUNDS, DGS10, DGS2, T10Y2Y, VIXCLS, CPIAUCSL, UNRATE)
**Calendar**: TickerCalendar, TickerEarningsHistory

All time-series tables use composite PK: `(ticker, date)`. Auto-cleanup deletes data older than 3 years.

### Ingest Format

Mac mini sends two payload formats (both supported):
- **Extended**: Nested objects (`{ items: [{ ticker, price: {...}, score: {...}, indicators: {...}, ... }] }`)
- **Simple**: Flat format (backward compatible, fewer fields)

The ingest endpoint does UPSERT into 11+ tables per item with trading day validation (skips weekends/holidays).

### Charts Endpoint (Primary Flutter Endpoint)

`GET /api/v1/charts/{ticker}` returns ALL data in one response: OHLCV prices, scores/signals, technical indicators, trendlines (pre-calculated JSONB arrays), targets, institutional/foreign ownership, short interest, AI analysis, company profile, fundamentals, financials, calendar events, earnings history.

### Key Conventions

- All public endpoints return **200 OK with empty structures** (never 404 for missing data)
- Korean signal translation at ingest: 매수→BUY, 매도→SELL, 관망→HOLD
- Trendline values are pre-calculated as JSONB arrays (`[{"date": "...", "y": 148.2}, ...]`) for direct Flutter rendering
- API key auth via `Depends(verify_api_key)` using `X-API-Key` header
- DB sessions via `Depends(get_db)` — SQLAlchemy `SessionLocal` with `yield`/`finally` pattern
- Pydantic v2 schemas with `from_attributes = True` for ORM mode

## Infrastructure

| Component | Technology |
|-----------|-----------|
| FastAPI ASGI | Uvicorn |
| Reverse Proxy | Nginx (path-based routing) |
| Database | PostgreSQL RDS (analytics schema) |
| AWS Server | 43.201.45.60 |
| SSH Key | ~/Downloads/hypehere-key.pem |

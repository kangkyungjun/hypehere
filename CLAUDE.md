# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository hosts **two separate products** sharing infrastructure:

1. **HypeHere** - Language learning social platform (Django)
2. **MarketLens** - Stock market analytics mobile app (FastAPI + Flutter)

These are **completely separate products** with separate user bases. They share a Django authentication server and PostgreSQL RDS instance but have no business logic overlap.

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    Nginx Reverse Proxy                      │
│  /                → Django (Daphne, Port 8000)             │
│  /api/v1/         → FastAPI (Uvicorn, Port 8001)           │
└────────────────────────────────────────────────────────────┘
         │                                  │
         ▼                                  ▼
  ┌──────────────┐                 ┌──────────────────┐
  │  Django       │                 │  FastAPI          │
  │  HypeHere     │                 │  MarketLens API   │
  │  (Read-Write) │                 │  (Read + Ingest)  │
  └──────────────┘                 └──────────────────┘
         │                                  │
         └──────────────┬───────────────────┘
                        ▼
            ┌────────────────────────┐
            │  PostgreSQL RDS        │
            │  public.*  → Django    │
            │  analytics.* → FastAPI │
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

### Data Flow (MarketLens)

Mac mini collects data (yfinance, finvizfinance, FRED) → processes/analyzes → POSTs to FastAPI `/api/v1/internal/ingest/` (API key protected) → FastAPI stores in `analytics.*` schema → Flutter app GETs from FastAPI public endpoints.

**CRITICAL**: FastAPI does NOT fetch external data. All data collection and AI analysis happens on Mac mini only. FastAPI is receive + serve.

## Development Commands

### Django (HypeHere)
```bash
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver                    # Port 8000
python manage.py createsuperuser              # Uses email, not username
python manage.py create_master                # Create MarketLens master account
```

### FastAPI (MarketLens)
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
# Apply manually to PostgreSQL RDS:
psql -h <rds-host> -U <user> -d hypehere -f fastapi_analytics/migrations/<filename>.sql
```

### Deployment
```bash
bash scripts/deploy.sh "commit message"           # Django
bash scripts/deploy_fastapi.sh "commit message"    # FastAPI
bash scripts/update_server.sh                      # Git pull on server
```

## Database Schema

**Single PostgreSQL RDS, dual schema**:
- `public.*` → Django ORM (HypeHere social features + shared auth)
- `analytics.*` → SQLAlchemy (MarketLens stock data, read-only from FastAPI except ingest)

```bash
# Django .env
DATABASE_URL=postgresql://user:pass@host:5432/hypehere

# FastAPI .env (in fastapi_analytics/)
DATABASE_ANALYTICS_URL=postgresql://analytics_user:pass@host:5432/hypehere?options=-c%20search_path=analytics
ANALYTICS_API_KEY=<key-for-mac-mini-ingest>
```

---

## MarketLens (FastAPI) Details

### FastAPI File Structure
```
fastapi_analytics/
├── app/
│   ├── main.py                    # App entry, 8 routers mounted
│   ├── config.py                  # Settings (DB URL, API key)
│   ├── database.py                # SQLAlchemy engine, SessionLocal, get_db()
│   ├── models.py                  # 17 SQLAlchemy models (analytics schema)
│   ├── schemas.py                 # Pydantic v2 request/response schemas
│   ├── utils/
│   │   └── trading_calendar.py    # is_trading_day() helper
│   ├── routers/
│   │   ├── scores.py              # /api/v1/scores/
│   │   ├── tickers.py             # /api/v1/tickers/
│   │   ├── prices.py              # /api/v1/prices/
│   │   ├── charts.py              # /api/v1/charts/ (all-in-one for Flutter)
│   │   ├── market.py              # /api/v1/market/
│   │   ├── macro.py               # /api/v1/macro/
│   │   ├── internal_ingest.py     # /api/v1/internal/ingest/ (Mac mini → AWS)
│   │   └── dashboard.py           # /dashboard (web UI)
│   └── services/                  # Business logic (empty for now)
└── migrations/                    # Raw SQL migration files
```

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

**Internal (Mac mini → AWS, API key required)**:
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

### Charts Endpoint (Key for Flutter)

`GET /api/v1/charts/{ticker}` returns ALL data in one response:
- OHLCV prices, scores/signals, technical indicators
- Trendlines (pre-calculated JSONB arrays for rendering)
- Targets (stop-loss, target price, analyst consensus)
- Institutional/foreign ownership with change deltas
- Short interest data
- AI analysis (probability, reasons, comment)
- Company profile, fundamentals, financials
- Calendar events, earnings history

This is the **primary endpoint** the Flutter app uses for the stock detail screen.

### MarketLens Role System (in Django accounts app)

5-tier hierarchy shared through Django auth:
- **Master**: Full admin (created via `python manage.py create_master`)
- **Manager**: User management (promote to Gold)
- **Gold**: Premium features
- **Regular**: Default new user
- **Guest**: Limited access

Relevant Django API endpoints:
- `POST /api/accounts/users/<id>/promote-to-gold/` (Manager+)
- `POST /api/accounts/users/<id>/promote-to-manager/` (Master only)
- `GET /api/accounts/users/search/` (Manager+)

---

## HypeHere (Django) Details

### Django Apps (7 apps)

1. **accounts** - Custom User model (email-based auth, not username), Follow/Block, MarketLens role system
2. **posts** - Social posts with hashtags, language fields, comments, likes, soft deletion
3. **chat** - 1:1 chat, anonymous matching chat, open group rooms (WebSocket via Channels)
4. **notifications** - Polymorphic notifications via ContentTypes, real-time WebSocket delivery
5. **learning** - SituationCategory → SituationLesson → SituationExpression hierarchy
6. **analytics** - HypeHere visitor tracking (DailyVisitor, UserActivityLog), admin dashboard
7. **specs** - Internal project management notes

### Authentication (CRITICAL)

```python
# USERNAME_FIELD = 'email' — NOT username
User.objects.create_user(email='user@example.com', nickname='Display Name', password='pass')
# username is auto-generated from email, never user-facing
```

### WebSocket Consumers (5 total, Django Channels)

| Consumer | URL | Key Behavior |
|----------|-----|-------------|
| ChatConsumer | `/ws/chat/<id>/` | 1:1 persistent chat, auto-rejoin, read receipts |
| AnonymousChatConsumer | `/ws/anonymous-chat/<id>/` | Ephemeral messages, WebRTC signaling |
| OpenChatConsumer | `/ws/open-chat/<room_id>/` | Group chat, admin system, password protection |
| MatchingConsumer | `/ws/matching/` | Match notifications |
| NotificationConsumer | `/ws/notifications/` | Real-time notifications |

Channel groups: `chat_{id}`, `anonymous_chat_{id}`, `open_chat_{room_id}`, `matching_{user_id}`, `user_notifications_{user_id}`

Dev: in-memory channel layer. Production: Redis/ElastiCache.

### Moderation System

- **Soft deletion**: `is_deleted_by_report` preserves `original_content`
- **Reports**: PostReport, CommentReport, Report (chat) → user.report_count
- **User states**: suspended (auto-lifts via middleware), banned, deactivated (30-day grace), deletion_requested

### i18n: ko (default), en, ja, es

## Infrastructure

| Component | Technology |
|-----------|-----------|
| Django ASGI | Daphne |
| FastAPI ASGI | Uvicorn |
| Reverse Proxy | Nginx (path-based routing) |
| Database | PostgreSQL RDS (dual schema) |
| Cache | ElastiCache Redis (Channels) |
| Storage | S3 (production static/media) |

### Systemd Services
```bash
sudo systemctl restart hypehere              # Django (Daphne)
sudo systemctl restart fastapi-analytics     # FastAPI (Uvicorn)
sudo systemctl restart nginx
```

## Key Implementation Notes

- FastAPI analytics schema migrations are raw SQL files, not Django ORM managed
- FastAPI never writes to `public.*`; Django never reads from `analytics.*`
- Mac mini is the sole data source for all stock market data
- Flutter app authenticates via Django, gets market data via FastAPI
- All FastAPI public endpoints return 200 OK with empty structures (never 404 for missing data)
- Korean signal translation happens at ingest: 매수→BUY, 매도→SELL, 관망→HOLD
- Trendline values are pre-calculated as JSONB arrays (`[{"date": "...", "y": 148.2}, ...]`) for direct Flutter rendering

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

**CRITICAL**: FastAPI does NOT fetch external data. All data collection and AI analysis happens on Mac mini only. FastAPI is receive + serve.

## Development Setup

### Environment

Copy `.env.example` to `.env` and fill in values. Generate a Django secret key:
```bash
python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

**Dev vs Production differences**:
- Dev: `DEBUG=True`, SQLite database, in-memory channel layer, local static/media files
- Prod: `DEBUG=False`, PostgreSQL RDS, Redis/ElastiCache channels, S3 storage

### Django (HypeHere)
```bash
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver                    # Port 8000 (Daphne ASGI)
python manage.py createsuperuser              # Uses email, not username
python manage.py create_master <email> <nickname> <password>  # MarketLens master account
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
psql -h <rds-host> -U <user> -d hypehere -f fastapi_analytics/migrations/<filename>.sql
```

### Testing & Linting

No test framework or linting tools are configured. All `tests.py` files are empty placeholders.

### Deployment
```bash
bash scripts/deploy.sh "commit message"           # Django: git push + SSH to AWS + update_server.sh
bash scripts/deploy_fastapi.sh "commit message"    # FastAPI: separate deployment
bash scripts/update_server.sh                      # Runs on AWS: pull, install deps, migrate, collectstatic, restart
```

Systemd services on AWS:
```bash
sudo systemctl restart daphne                # Django (HypeHere)
sudo systemctl restart marketlens-django     # Django (MarketLens-specific)
sudo systemctl restart fastapi-analytics     # FastAPI
sudo systemctl restart nginx
```

## Database Schema

**Single PostgreSQL RDS, dual schema**:
- `public.*` → Django ORM (HypeHere social features + shared auth)
- `analytics.*` → SQLAlchemy (MarketLens stock data)

**Schema boundary rule**: FastAPI never writes to `public.*`; Django never reads from `analytics.*`.

```bash
# Django .env
DATABASE_URL=postgresql://user:pass@host:5432/hypehere

# FastAPI .env (in fastapi_analytics/)
DATABASE_ANALYTICS_URL=postgresql://analytics_user:pass@host:5432/hypehere?options=-c%20search_path=analytics
ANALYTICS_API_KEY=<key-for-mac-mini-ingest>
```

---

## MarketLens (FastAPI) Details

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

Note: `lotto` app loads conditionally if the directory exists (local dev only, git-ignored).

### Authentication (CRITICAL)

```python
# USERNAME_FIELD = 'email' — NOT username
User.objects.create_user(email='user@example.com', nickname='Display Name', password='pass')
# username is auto-generated from email prefix, never user-facing
```

**Auth methods**: Token auth (DRF `rest_framework.authtoken`) + Session auth. Both enabled in DRF settings.

### Custom Middleware

- **`SuspensionCheckMiddleware`** (`accounts/middleware.py`): Auto-lifts expired suspensions by calling `user.lift_suspension()` on each request
- **`VisitorTrackingMiddleware`** (`analytics/middleware.py`): Tracks DailyVisitor (IP + user) and UserActivityLog; handles `X-Forwarded-For` for reverse proxy; uses `try/except IntegrityError` for race conditions

### URL Routing Pattern

Django URLs split by app with these prefixes:
- `accounts/` — HTML views (login, register, profile pages)
- `api/accounts/` — REST API (user search, role management)
- `api/posts/` and `api/community/posts/` — Post CRUD (same app, dual mount for MarketLens)
- `api/chat/` — Chat REST API; `messages/` — Chat HTML views
- `notifications/` — Both views and API (nested at `notifications/api/`)
- `learning/` — Learning API (nested at `learning/api/`)
- `admin-dashboard/` — Analytics dashboard

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

### MarketLens Role System (in Django accounts app)

5-tier hierarchy: Master > Manager > Gold > Regular > Guest
- `python manage.py create_master` creates initial admin
- `POST /api/accounts/users/<id>/promote-to-gold/` (Manager+)
- `POST /api/accounts/users/<id>/promote-to-manager/` (Master only)
- `POST /api/accounts/users/<id>/demote-to-regular/` (Master only)
- `GET /api/accounts/users/search/` (Manager+)

### i18n: ko (default), en, ja, es

## Infrastructure

| Component | Technology |
|-----------|-----------|
| Django ASGI | Daphne |
| FastAPI ASGI | Uvicorn |
| Reverse Proxy | Nginx (path-based routing) |
| Database | PostgreSQL RDS (dual schema) |
| Cache | ElastiCache Redis (Channels) |
| Storage | S3 (production static/media), WhiteNoise fallback |
| Email | Gmail SMTP (requires app-specific password) |

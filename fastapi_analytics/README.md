# HypeHere Ticker Analytics API

**MVP-focused, read-only FastAPI service** for serving pre-computed ticker scores from Mac mini.

## 🎯 Purpose

- **Read-only** ticker scoring API
- Serves data from PostgreSQL `analytics` schema
- **Independent** from Django server
- Optimized for **high-frequency mobile app queries**

## 📊 Architecture

```
Mac mini (daily AI analysis)
    ↓ compute & upload
PostgreSQL analytics.ticker_scores
    ↓ read-only
FastAPI (this service)
    ↓ HTTP GET
Mobile App (charts & rankings)
```

## ✅ MVP API Endpoints (3 endpoints only)

### 1. Get Ticker Score History ⭐⭐⭐
```http
GET /api/v1/scores/{ticker}?from=YYYY-MM-DD&to=YYYY-MM-DD
```

**Purpose**: 종목 점수 기록 조회 (차트용)

**Example**:
```bash
curl "http://localhost:8001/api/v1/scores/AAPL?from=2026-01-01&to=2026-02-02"
```

**Response**:
```json
{
  "ticker": "AAPL",
  "scores": [
    {"date": "2026-01-01", "score": 85.2, "signal": "BUY"},
    {"date": "2026-01-02", "score": 87.1, "signal": "BUY"},
    {"date": "2026-01-03", "score": 86.5, "signal": "HOLD"}
  ]
}
```

### 2. Get Top Tickers ⭐
```http
GET /api/v1/scores/top?date=YYYY-MM-DD&limit=10
```

**Purpose**: 상위 종목 목록 (홈 화면용)

**Example**:
```bash
curl "http://localhost:8001/api/v1/scores/top?date=2026-02-02&limit=10"
```

**Response**:
```json
[
  {
    "ticker": "AAPL",
    "score": 92.5,
    "signal": "BUY",
    "name": "Apple Inc."
  },
  {
    "ticker": "TSLA",
    "score": 88.3,
    "signal": "HOLD",
    "name": "Tesla, Inc."
  }
]
```

### 3. Search Tickers ⭐
```http
GET /api/v1/tickers/search?q={query}
```

**Purpose**: 종목 검색 (메타데이터)

**Example**:
```bash
curl "http://localhost:8001/api/v1/tickers/search?q=apple"
```

**Response**:
```json
[
  {
    "ticker": "AAPL",
    "name": "Apple Inc.",
    "category": "Technology"
  }
]
```

## 🗄️ Database Schema

### analytics.ticker_scores (⭐⭐⭐ 핵심)
```sql
CREATE TABLE analytics.ticker_scores (
    ticker VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    score FLOAT NOT NULL,
    signal VARCHAR(10),  -- BUY/SELL/HOLD
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ticker, date)
);
```

**Purpose**: Mac mini가 계산한 일일 점수 저장

### analytics.tickers (⭐ 메타데이터)
```sql
CREATE TABLE analytics.tickers (
    ticker VARCHAR(50) PRIMARY KEY,
    ticker_type VARCHAR(50),
    ticker_name VARCHAR(200),
    name VARCHAR(200),
    category VARCHAR(50)
);
```

**Purpose**: 검색 및 표시용 메타데이터

## 🚀 Quick Start

### Setup

```bash
# Create virtual environment
cd fastapi_analytics
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
echo "DATABASE_ANALYTICS_URL=postgresql://user:pass@host:5432/hypehere?options=-c%20search_path=analytics" > .env
```

### Run Locally

```bash
# Development server with auto-reload
uvicorn app.main:app --reload --port 8001

# Access API documentation
# Swagger UI: http://localhost:8001/docs
# ReDoc: http://localhost:8001/redoc
```

## 📁 Project Structure

```
fastapi_analytics/
├── app/
│   ├── __init__.py
│   ├── main.py           # FastAPI app (3 endpoints)
│   ├── config.py         # Settings
│   ├── database.py       # SQLAlchemy connection
│   ├── models.py         # TickerScore, Ticker models
│   ├── schemas.py        # Pydantic schemas (simplified)
│   ├── routers/
│   │   ├── scores.py     # ⭐⭐⭐ Ticker score endpoints
│   │   └── tickers.py    # ⭐ Ticker search endpoint
│   └── services/
├── .env                  # DATABASE_ANALYTICS_URL
├── requirements.txt
└── README.md
```

## 🎯 MVP Design Principles

### ✅ What We Kept
- **ticker + date + score** - Core data model
- **GET-only endpoints** - Read-only API
- **Simple responses** - Easy to consume

### ❌ What We Removed
- ~~entity_type~~ (user/post/comment) - Feature Store concept
- ~~score_type~~ (engagement/quality) - Not calculated yet
- ~~trending/by-engagement~~ - Belongs in scores, not tickers
- ~~Complex abstractions~~ - MVP focuses on clarity

### 🔮 What We Can Add Later
- Additional score types (when Mac mini calculates them)
- More complex filtering
- Aggregations and statistics
- Caching layer

## 🚢 Deployment

### Production Server (AWS EC2)

```bash
# Install dependencies
cd /home/django/hypehere/fastapi_analytics
source venv/bin/activate
pip install -r requirements.txt

# Run with Uvicorn (systemd service)
sudo systemctl start fastapi-analytics
sudo systemctl status fastapi-analytics
```

### Nginx Configuration

```nginx
location /api/v1/ {
    proxy_pass http://127.0.0.1:8001;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

## 📝 Notes

### Canonical vs Serving Layer
- **Canonical (Feature Store)**: Mac mini internal, complex calculations
- **Serving (this API)**: Simple ticker + date + score model
- **Clear separation**: No feature engineering in serving layer

### Database Access
- **Schema**: `analytics` only (isolated from Django's `public`)
- **Permissions**: Read-only for FastAPI
- **Connection**: Shared RDS, different schemas

### Security
- **RDS**: Only accessible from EC2 (security group)
- **Local development**: Cannot connect to RDS (this is correct!)
- **API**: GET-only, no authentication required (public data)

## 🔗 Related

- **Django server**: `/home/django/hypehere/` (main application)
- **Database**: PostgreSQL RDS (dual schema: `public` + `analytics`)
- **Mac mini**: Daily analysis upload scripts
- **Mobile app**: Consumes this API for charts and rankings

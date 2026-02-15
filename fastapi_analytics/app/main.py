from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.routers import scores, tickers, prices, internal_ingest, dashboard, charts, market, macro, earnings
from app.config import settings
from app.schemas import HealthCheck

# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.VERSION,
    description="Read-only ticker scoring API for HypeHere mobile app",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Restrict in production
    allow_credentials=True,
    allow_methods=["GET", "POST"],  # GET for public API, POST for internal ingest
    allow_headers=["*"],
)

# Mount static files (using /analytics-static to avoid conflict with Django static files)
app.mount("/analytics-static", StaticFiles(directory="app/static"), name="static")

# Include routers
app.include_router(
    scores.router,
    prefix="/api/v1/scores",
    tags=["Ticker Scores ⭐⭐⭐"]
)

app.include_router(
    tickers.router,
    prefix="/api/v1/tickers",
    tags=["Ticker Metadata ⭐"]
)

app.include_router(
    prices.router,
    prefix="/api/v1/prices",
    tags=["Ticker Prices ⭐⭐"]
)

# Complete chart data router (Flutter app)
app.include_router(
    charts.router,
    prefix="/api/v1/charts",
    tags=["Complete Chart Data ⭐⭐⭐"]
)

# Market overview router (treemap)
app.include_router(
    market.router,
    prefix="/api/v1/market",
    tags=["Market Overview"]
)

# Macro indicators router (Dashboard)
app.include_router(
    macro.router,
    prefix="/api/v1/macro",
    tags=["Macro Indicators"]
)

# Earnings calendar router (Flutter app)
app.include_router(
    earnings.router,
    prefix="/api/v1/earnings",
    tags=["Earnings Calendar"]
)

# Internal router (Mac mini ingest)
app.include_router(internal_ingest.router)

# Dashboard router (public web interface)
app.include_router(dashboard.router)


@app.get("/", tags=["Root"])
def root():
    """
    API information and endpoint examples
    """
    return {
        "message": "HypeHere Ticker Analytics API",
        "version": settings.VERSION,
        "description": "Read-only ticker scoring API",
        "endpoints": {
            "scores": "/api/v1/scores/{ticker}?from=2026-01-01&to=2026-02-02",
            "top": "/api/v1/scores/top?date=2026-02-02&limit=10",
            "search": "/api/v1/tickers/search?q=AAPL",
            "ticker_info": "/api/v1/tickers/{ticker}",
            "treemap": "/api/v1/market/treemap?date=2026-02-14"
        },
        "docs": {
            "swagger": "/docs",
            "redoc": "/redoc"
        }
    }


@app.get("/health", response_model=HealthCheck, tags=["Health"])
def health_check():
    """
    Health check endpoint
    """
    return {
        "status": "healthy",
        "service": "fastapi-analytics",
        "version": settings.VERSION
    }


@app.on_event("startup")
async def startup_event():
    """Execute on application startup"""
    print(f"🚀 {settings.APP_NAME} v{settings.VERSION} starting...")
    print(f"📊 Read-only ticker scoring API")
    print(f"✅ Endpoints: /api/v1/scores, /api/v1/tickers")


@app.on_event("shutdown")
async def shutdown_event():
    """Execute on application shutdown"""
    print(f"🛑 {settings.APP_NAME} shutting down...")

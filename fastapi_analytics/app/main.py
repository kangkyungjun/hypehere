from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import scores, tickers
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
    allow_methods=["GET"],  # Read-only API
    allow_headers=["*"],
)

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
            "ticker_info": "/api/v1/tickers/{ticker}"
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

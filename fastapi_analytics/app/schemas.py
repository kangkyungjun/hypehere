from pydantic import BaseModel, Field
from datetime import date as Date
from typing import Optional, List


# ============================================================
# Ticker Score Schemas (⭐⭐⭐ MVP 핵심)
# ============================================================

class TickerScoreResponse(BaseModel):
    """Single ticker score data point"""
    date: Date = Field(..., description="Score calculation date")
    score: float = Field(..., description="Calculated score value")
    signal: Optional[str] = Field(None, description="Trading signal: BUY/SELL/HOLD")

    class Config:
        from_attributes = True


class TickerScoreListResponse(BaseModel):
    """Ticker with score history (for charts)"""
    ticker: str = Field(..., description="Ticker symbol")
    scores: List[TickerScoreResponse] = Field(..., description="Historical scores")


class TopTickerResponse(BaseModel):
    """Top ticker for homepage display"""
    ticker: str = Field(..., description="Ticker symbol")
    score: float = Field(..., description="Latest score")
    signal: Optional[str] = Field(None, description="Trading signal")
    name: Optional[str] = Field(None, description="Human-readable name")

    class Config:
        from_attributes = True


# ============================================================
# Ticker Metadata Schemas (⭐ 검색/메타)
# ============================================================

class TickerMetadata(BaseModel):
    """Ticker basic information"""
    ticker: str = Field(..., description="Ticker symbol")
    name: Optional[str] = Field(None, description="Display name")
    category: Optional[str] = Field(None, description="Category/sector")

    class Config:
        from_attributes = True


# ============================================================
# Common Response Schemas
# ============================================================

class HealthCheck(BaseModel):
    """Health check response"""
    status: str
    service: str
    version: str


class ErrorResponse(BaseModel):
    """Error response schema"""
    detail: str

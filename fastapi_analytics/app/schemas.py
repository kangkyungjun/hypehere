from pydantic import BaseModel, Field
from datetime import date as Date
from typing import Optional, List, Union


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


# ============================================================
# Ticker Price Schemas (⭐⭐ 차트용)
# ============================================================

class TickerPriceResponse(BaseModel):
    """Single ticker price data point (OHLCV)"""
    date: Date = Field(..., description="Price data date")
    open: Optional[float] = Field(None, description="Open price")
    high: Optional[float] = Field(None, description="High price")
    low: Optional[float] = Field(None, description="Low price")
    close: Optional[float] = Field(None, description="Close price")
    volume: Optional[int] = Field(None, description="Trading volume")

    class Config:
        from_attributes = True


class TickerPriceListResponse(BaseModel):
    """Ticker with price history (for charting)"""
    ticker: str = Field(..., description="Ticker symbol")
    prices: List[TickerPriceResponse] = Field(..., description="Historical OHLCV data")


# ============================================================
# Complete Chart Data Schemas (⭐⭐⭐ Flutter 최적화)
# ============================================================

class ChartDataPoint(BaseModel):
    """
    Single day complete chart data.
    Combines price, score, indicators, targets for Flutter app.
    """
    date: Date = Field(..., description="Data date")

    # Price data (OHLCV)
    open: Optional[float] = Field(None, description="Open price")
    high: Optional[float] = Field(None, description="High price")
    low: Optional[float] = Field(None, description="Low price")
    close: Optional[float] = Field(None, description="Close price")
    volume: Optional[int] = Field(None, description="Trading volume")

    # Score data
    score: Optional[float] = Field(None, description="AI score")
    signal: Optional[str] = Field(None, description="BUY/SELL/HOLD signal")

    # Target levels
    target_price: Optional[float] = Field(None, description="Target price")
    stop_loss: Optional[float] = Field(None, description="Stop loss price")

    # Technical indicators
    rsi: Optional[float] = Field(None, description="RSI (0-100)")
    macd: Optional[float] = Field(None, description="MACD line")
    macd_signal: Optional[float] = Field(None, description="MACD signal line")
    macd_hist: Optional[float] = Field(None, description="MACD histogram")
    bb_width: Optional[float] = Field(None, description="Bollinger Band width")
    bb_upper: Optional[float] = Field(None, description="BB upper band")
    bb_lower: Optional[float] = Field(None, description="BB lower band")
    bb_middle: Optional[float] = Field(None, description="BB middle band")

    # Institutional data
    inst_ownership: Optional[float] = Field(None, description="Institutional ownership %")
    foreign_ownership: Optional[float] = Field(None, description="Foreign ownership %")
    inst_chg_1d: Optional[float] = Field(None, description="1-day institutional change")
    inst_chg_5d: Optional[float] = Field(None, description="5-day institutional change")
    foreign_chg_1d: Optional[float] = Field(None, description="1-day foreign change")
    foreign_chg_5d: Optional[float] = Field(None, description="5-day foreign change")

    # Short data
    short_ratio: Optional[float] = Field(None, description="Days to cover")
    short_percent_float: Optional[float] = Field(None, description="Short % of float")

    # AI Analysis data
    ai_probability: Optional[float] = Field(None, description="AI prediction confidence (0.0-1.0)")
    ai_summary: Optional[str] = Field(None, description="AI analysis summary")
    ai_bullish_reasons: Optional[List[str]] = Field(None, description="Bullish factors")
    ai_bearish_reasons: Optional[List[str]] = Field(None, description="Bearish factors")
    ai_final_comment: Optional[str] = Field(None, description="AI final recommendation")


class CompleteChartResponse(BaseModel):
    """
    Complete chart data for Flutter app (1 API call gets everything).

    Flutter 앱이 이 API 한 번만 호출하면:
    - 가격 차트 (Candlestick)
    - 점수 차트 (Line)
    - RSI/MACD 차트 (아래 패널)
    - 목표가/손절가 수평선
    - 추세선 (오버레이)
    - 기관/외인 데이터
    - 공매도 데이터

    모두 렌더링 가능.
    """
    ticker: str = Field(..., description="Ticker symbol")
    data: List[ChartDataPoint] = Field(..., description="Time series data")

    # Trendlines (latest calculation)
    high_slope: Optional[float] = Field(None, description="High trendline slope")
    high_intercept: Optional[float] = Field(None, description="High trendline intercept")
    high_r_squared: Optional[float] = Field(None, description="High trendline R²")
    low_slope: Optional[float] = Field(None, description="Low trendline slope")
    low_intercept: Optional[float] = Field(None, description="Low trendline intercept")
    low_r_squared: Optional[float] = Field(None, description="Low trendline R²")


# ============================================================
# Internal Ingest Schemas (Mac mini → FastAPI)
# ============================================================

class PriceData(BaseModel):
    """OHLCV price data (nested structure)"""
    open: float = Field(..., description="Open price")
    high: float = Field(..., description="High price")
    low: float = Field(..., description="Low price")
    close: float = Field(..., description="Close price")
    volume: int = Field(..., description="Trading volume")


class ScoreData(BaseModel):
    """Score and signal data (nested structure)"""
    value: float = Field(..., ge=0, le=100, description="Score value (0-100)")
    signal: str = Field(..., description="Trading signal (BUY/SELL/HOLD or Korean)")


class IndicatorData(BaseModel):
    """Technical indicators (nested structure)"""
    rsi: Optional[float] = Field(None, description="RSI (0-100)")
    macd: Optional[float] = Field(None, description="MACD line")
    macd_signal: Optional[float] = Field(None, description="MACD signal line")
    macd_hist: Optional[float] = Field(None, description="MACD histogram")
    bb_upper: Optional[float] = Field(None, description="BB upper band")
    bb_middle: Optional[float] = Field(None, description="BB middle band")
    bb_lower: Optional[float] = Field(None, description="BB lower band")


class AIAnalysisData(BaseModel):
    """AI analysis results (nested structure)"""
    probability: float = Field(..., ge=0, le=1, description="Prediction confidence (0.0-1.0)")
    summary: str = Field(..., max_length=200, description="Brief analysis summary")
    bullish_reasons: List[str] = Field(..., description="List of bullish factors")
    bearish_reasons: List[str] = Field(..., description="List of bearish factors")
    final_comment: str = Field(..., max_length=500, description="Final recommendation")


class ExtendedItemIngest(BaseModel):
    """
    Extended payload format from Mac mini (nested structure).

    Supports nested objects: price, score, indicators, ai_analysis
    """
    date: Date = Field(..., description="Data date")
    ticker: str = Field(..., max_length=10, description="Ticker symbol")
    price: PriceData = Field(..., description="OHLCV price data")
    score: ScoreData = Field(..., description="Score and signal")
    indicators: IndicatorData = Field(..., description="Technical indicators")
    ai_analysis: AIAnalysisData = Field(..., description="AI analysis results")


class SimpleItemIngest(BaseModel):
    """
    Simple flat payload format (backward compatibility).

    Supports flat structure like existing implementation.
    """
    date: Date = Field(..., description="Data date")
    ticker: str = Field(..., max_length=10, description="Ticker symbol")
    score: float = Field(..., ge=0, le=100, description="Score value")
    signal: str = Field(..., description="Trading signal")

    # Optional price fields (flat)
    open: Optional[float] = Field(None, description="Open price")
    high: Optional[float] = Field(None, description="High price")
    low: Optional[float] = Field(None, description="Low price")
    close: Optional[float] = Field(None, description="Close price")
    volume: Optional[int] = Field(None, description="Trading volume")

    # Optional indicator fields (flat)
    rsi: Optional[float] = Field(None, description="RSI")
    macd: Optional[float] = Field(None, description="MACD line")
    macd_signal: Optional[float] = Field(None, description="MACD signal")
    macd_hist: Optional[float] = Field(None, description="MACD histogram")
    bb_width: Optional[float] = Field(None, description="BB width")
    bb_upper: Optional[float] = Field(None, description="BB upper")
    bb_lower: Optional[float] = Field(None, description="BB lower")
    bb_middle: Optional[float] = Field(None, description="BB middle")


class IngestPayload(BaseModel):
    """
    Top-level ingest payload supporting both extended and simple formats.

    Uses Union type for backward compatibility.
    FastAPI will automatically validate and discriminate between formats.
    """
    items: List[Union[ExtendedItemIngest, SimpleItemIngest]] = Field(
        ...,
        description="List of ticker data items (extended or simple format)"
    )

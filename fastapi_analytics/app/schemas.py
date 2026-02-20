from pydantic import BaseModel, Field
from datetime import date as Date, datetime as DateTime
from typing import Optional, List, Union, Dict, Literal


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
    name_ko: Optional[str] = Field(None, description="Korean name (e.g., '애플')")
    membership: Optional[List[str]] = Field(None, description="Index membership (e.g., ['SP500', 'DOW30'])")

    class Config:
        from_attributes = True


# ============================================================
# Ticker Metadata Schemas (⭐ 검색/메타)
# ============================================================

class TickerMetadata(BaseModel):
    """Ticker basic information"""
    ticker: str = Field(..., description="Ticker symbol")
    name: Optional[str] = Field(None, description="Display name (English)")
    name_ko: Optional[str] = Field(None, description="Korean name (e.g., '애플')")
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
    mfi: Optional[float] = Field(None, description="MFI (0-100)")
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
    insider_ownership: Optional[float] = Field(None, description="Insider ownership %")
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


class TrendlineValue(BaseModel):
    """Single trendline data point with date and y-value"""
    date: str = Field(..., description="Date in YYYY-MM-DD format")
    y: float = Field(..., description="Trendline y-value for this date")


class AnalystConsensus(BaseModel):
    """yfinance analyst consensus target prices"""
    mean: Optional[float] = Field(None, description="Mean target price")
    high: Optional[float] = Field(None, description="Highest target price")
    low: Optional[float] = Field(None, description="Lowest target price")
    count: Optional[int] = Field(None, description="Number of covering analysts")
    recommendation: Optional[str] = Field(None, description="Consensus recommendation (buy/hold/sell)")


class AnalystRatingItem(BaseModel):
    """Individual institutional analyst report"""
    date: Optional[str] = Field(None, description="Report publication date")
    status: Optional[str] = Field(None, description="Upgrade/Downgrade/Reiterated/Initiated")
    firm: Optional[str] = Field(None, description="Institution name")
    rating: Optional[str] = Field(None, description="Investment opinion")
    target_from: Optional[float] = Field(None, description="Previous target price")
    target_to: Optional[float] = Field(None, description="New target price")


class CompanyProfileResponse(BaseModel):
    """Company profile data (non-time-series)"""
    long_name: Optional[str] = None
    industry: Optional[str] = None
    website: Optional[str] = None
    country: Optional[str] = None
    employees: Optional[int] = None
    summary: Optional[str] = None


class KeyMetricsResponse(BaseModel):
    """Key valuation and financial metrics (latest snapshot)"""
    market_cap: Optional[float] = None
    pe: Optional[float] = None
    forward_pe: Optional[float] = None
    peg: Optional[float] = None
    pb: Optional[float] = None
    ps: Optional[float] = None
    ev_revenue: Optional[float] = None
    ev_ebitda: Optional[float] = None
    profit_margin: Optional[float] = None
    operating_margin: Optional[float] = None
    gross_margin: Optional[float] = None
    roe: Optional[float] = None
    roa: Optional[float] = None
    debt_to_equity: Optional[float] = None
    current_ratio: Optional[float] = None
    beta: Optional[float] = None
    dividend_yield: Optional[float] = None
    payout_ratio: Optional[float] = None
    earnings_growth: Optional[float] = None
    revenue_growth: Optional[float] = None


class FinancialsResponse(BaseModel):
    """Financial statements (JSONB snapshots)"""
    latest_quarter: Optional[str] = None
    income: Optional[dict] = None
    balance_sheet: Optional[dict] = None
    cash_flow: Optional[dict] = None


class DividendEntry(BaseModel):
    """Single dividend payment entry"""
    ex_date: str
    amount: Optional[float] = None


# ============================================================
# Macro Indicator Schemas
# ============================================================

class MacroIndicatorItem(BaseModel):
    """Single macro indicator value from Mac mini"""
    value: float
    observation_date: Optional[str] = None
    name: Optional[str] = None
    risk_level: Optional[str] = None       # BULLISH/POSITIVE/NEUTRAL/CAUTIOUS/BEARISH
    signal_message: Optional[str] = None    # 한국어 설명 (e.g., "금리 긴축적")


class MacroSignalItem(BaseModel):
    """시장레이더/머니프린팅 신호 (signals.yield_curve, signals.m2_liquidity)"""
    value: float
    risk_level: Optional[str] = None       # CRITICAL/WARNING/NORMAL
    liquidity_status: Optional[str] = None  # EXPANDING/CONTRACTING/NEUTRAL
    signal_message: Optional[str] = None    # 한국어 설명


class MacroChartPoint(BaseModel):
    """차트 시계열 포인트"""
    date: str
    value: float


class MacroIngestPayload(BaseModel):
    """
    Macro indicators ingest payload from Mac mini.

    Supports both legacy flat indicators and new signals+charts:
    - indicators: {code: {value, observation_date, name}} (기존 FRED 지표)
    - signals: {yield_curve: {...}, m2_liquidity: {...}} (시장레이더/머니프린팅)
    - charts: {t10y2y: [{date, value}], m2_growth: [{date, value}]} (시계열 차트)
    """
    date: str
    indicators: Optional[Dict[str, MacroIndicatorItem]] = None  # 기존 호환
    signals: Optional[Dict[str, MacroSignalItem]] = None         # 신규
    charts: Optional[Dict[str, List[MacroChartPoint]]] = None    # 신규


class MacroIndicatorResponse(BaseModel):
    """Single macro indicator in API response"""
    indicator_code: str
    indicator_name: Optional[str] = None
    value: float
    observation_date: Optional[str] = None
    previous_value: Optional[float] = None
    change_pct: Optional[float] = None
    risk_level: Optional[str] = None
    liquidity_status: Optional[str] = None
    signal_message: Optional[str] = None


class MacroIndicatorsResponse(BaseModel):
    """Macro indicators API response"""
    date: str
    indicators: List[MacroIndicatorResponse]


class MacroSignalResponse(BaseModel):
    """Single macro signal in API response"""
    signal_code: str
    value: float
    risk_level: Optional[str] = None
    liquidity_status: Optional[str] = None
    message: Optional[str] = None
    date: str


class MacroSignalsResponse(BaseModel):
    """Macro signals API response"""
    date: str
    signals: List[MacroSignalResponse]


class MacroChartPointResponse(BaseModel):
    """Single chart data point"""
    date: str
    value: float


class MacroChartResponse(BaseModel):
    """Macro chart time-series API response"""
    series_id: str
    count: int
    data: List[MacroChartPointResponse]


# ============================================================
# Market Indices Schemas
# ============================================================

class IndexChartPoint(BaseModel):
    """스파크라인 차트 포인트"""
    date: str
    close: float


class MarketIndexItem(BaseModel):
    """단일 지수 ingest 데이터 (Mac mini → AWS)"""
    code: str
    name: str
    close: float
    prev_close: float
    change: float
    change_pct: float
    open: float
    high: float
    low: float
    volume: int
    chart: List[IndexChartPoint] = []


class MarketIndicesIngestPayload(BaseModel):
    """시장 지수 ingest payload (Mac mini → AWS)"""
    date: str
    indices: List[MarketIndexItem]


class MarketIndexResponse(BaseModel):
    """단일 지수 응답 (Flutter용)"""
    code: str
    name: str
    close: float
    prev_close: float
    change: float
    change_pct: float
    open: Optional[float] = None
    high: Optional[float] = None
    low: Optional[float] = None
    volume: Optional[int] = None
    chart: List[IndexChartPoint] = []

    class Config:
        from_attributes = True


class MarketIndicesResponse(BaseModel):
    """시장 지수 전체 응답 (Flutter용)"""
    date: str
    indices: List[MarketIndexResponse]


# ============================================================
# Calendar & Earnings Schemas
# ============================================================

class CalendarData(BaseModel):
    """Calendar data from Mac mini ingest"""
    next_earnings_date: Optional[str] = None
    next_earnings_date_end: Optional[str] = None
    earnings_confirmed: Optional[bool] = None
    d_day: Optional[int] = None
    ex_dividend_date: Optional[str] = None
    dividend_date: Optional[str] = None
    earnings_estimate: Optional[dict] = None
    revenue_estimate: Optional[dict] = None

class EarningsHistoryEntry(BaseModel):
    """Single earnings history entry from Mac mini"""
    date: str
    eps_estimate: Optional[float] = None
    reported_eps: Optional[float] = None
    surprise_pct: Optional[float] = None

class CalendarResponse(BaseModel):
    """Calendar data in chart API response"""
    next_earnings_date: Optional[str] = None
    next_earnings_date_end: Optional[str] = None
    earnings_confirmed: Optional[bool] = None
    d_day: Optional[int] = None
    urgency: Optional[str] = None
    earnings_days_remaining: Optional[int] = None
    ex_dividend_date: Optional[str] = None
    dividend_date: Optional[str] = None
    earnings_estimate: Optional[dict] = None
    revenue_estimate: Optional[dict] = None

class EarningsHistoryItem(BaseModel):
    """Earnings history item in chart API response"""
    date: str
    eps_estimate: Optional[float] = None
    reported_eps: Optional[float] = None
    surprise_pct: Optional[float] = None


class DefenseLineResponse(BaseModel):
    """이동평균 방어선 (response용)"""
    period: int
    price: float
    label: Optional[str] = None
    distance_pct: Optional[float] = None


class RecommendationsResponse(BaseModel):
    """애널리스트 의견분포 (response용)"""
    strong_buy: int = 0
    buy: int = 0
    hold: int = 0
    sell: int = 0
    strong_sell: int = 0
    consensus_score: Optional[float] = None


class InstitutionalHolderResponse(BaseModel):
    """Individual institutional holder in API response"""
    holder: str
    pct_held: Optional[float] = None
    pct_change: Optional[float] = None


class NewsItemResponse(BaseModel):
    """Single news item in public API response"""
    date: Date
    ticker: str
    title: str
    source: Optional[str] = None
    source_url: Optional[str] = None
    published_at: DateTime
    ai_summary: str
    sentiment_score: int
    sentiment_grade: str
    sentiment_label: str
    future_event: Optional[dict] = None

    class Config:
        from_attributes = True


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
    - 기업 프로필/밸류에이션/재무/배당

    모두 렌더링 가능.
    """
    ticker: str = Field(..., description="Ticker symbol")
    data: List[ChartDataPoint] = Field(..., description="Time series data")

    # Trendlines (latest calculation)
    high_slope: Optional[float] = Field(None, description="High trendline slope")
    high_intercept: Optional[float] = Field(None, description="High trendline intercept")
    high_r_squared: Optional[float] = Field(None, description="High trendline R²")
    high_values: Optional[List[TrendlineValue]] = Field(None, description="Pre-calculated high trendline y-values")
    low_slope: Optional[float] = Field(None, description="Low trendline slope")
    low_intercept: Optional[float] = Field(None, description="Low trendline intercept")
    low_r_squared: Optional[float] = Field(None, description="Low trendline R²")
    low_values: Optional[List[TrendlineValue]] = Field(None, description="Pre-calculated low trendline y-values")

    # Analyst data (latest snapshot, not time-series)
    analyst_consensus: Optional[AnalystConsensus] = Field(None, description="Analyst consensus target prices")
    analyst_ratings: Optional[List[AnalystRatingItem]] = Field(None, description="Individual analyst ratings")

    # Fundamentals (latest snapshot, not time-series)
    profile: Optional[CompanyProfileResponse] = Field(None, description="Company profile")
    key_metrics: Optional[KeyMetricsResponse] = Field(None, description="Key valuation metrics")
    financials: Optional[FinancialsResponse] = Field(None, description="Financial statements")
    dividends: Optional[List[DividendEntry]] = Field(None, description="Recent dividend history")
    calendar: Optional[CalendarResponse] = Field(None, description="Calendar events (earnings, dividends)")
    earnings_history: Optional[List[EarningsHistoryItem]] = Field(None, description="Earnings history (EPS estimate vs reported)")

    # Phase 2: New data sources
    defense_lines: Optional[List[DefenseLineResponse]] = Field(None, description="Moving average defense lines")
    recommendations: Optional[RecommendationsResponse] = Field(None, description="Analyst recommendations distribution")
    institutional_holders: Optional[List[InstitutionalHolderResponse]] = Field(None, description="Top institutional holders")

    # News (latest 5 articles)
    news: Optional[List[NewsItemResponse]] = Field(None, description="Latest news articles")


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
    bb_width: Optional[float] = Field(None, description="BB width")
    mfi: Optional[float] = Field(None, description="MFI (0-100)")


class AIAnalysisData(BaseModel):
    """AI analysis results (nested structure)"""
    probability: float = Field(..., ge=0, le=1, description="Prediction confidence (0.0-1.0)")
    summary: str = Field(..., max_length=200, description="Brief analysis summary")
    bullish_reasons: List[str] = Field(..., description="List of bullish factors")
    bearish_reasons: List[str] = Field(..., description="List of bearish factors")
    final_comment: str = Field(..., max_length=500, description="Final recommendation")


class TrendlineCoefficients(BaseModel):
    """Trendline coefficients and pre-calculated values"""
    slope: Optional[float] = Field(None, description="Trendline slope")
    intercept: Optional[float] = Field(None, description="Trendline intercept")
    r_sq: Optional[float] = Field(None, description="R² coefficient")
    values: Optional[List[TrendlineValue]] = Field(None, description="Pre-calculated y-values")


class TrendData(BaseModel):
    """Trendline data (nested structure from Mac mini)"""
    high: Optional[TrendlineCoefficients] = Field(None, description="High price trendline")
    low: Optional[TrendlineCoefficients] = Field(None, description="Low price trendline")


class MarketData(BaseModel):
    """Daily market data for treemap (nested structure)"""
    change_pct: Optional[float] = Field(None, description="Daily price change %")
    trading_value: Optional[float] = Field(None, description="close * volume (USD)")


class DefenseLine(BaseModel):
    """이동평균 방어선 데이터"""
    period: int = Field(..., description="Moving average period (e.g., 20, 50, 200)")
    price: float = Field(..., description="Moving average price")
    label: Optional[str] = Field(None, description="Display label (e.g., 'MA20')")
    distance_pct: Optional[float] = Field(None, description="Distance from current price %")


class RecommendationsData(BaseModel):
    """애널리스트 의견분포"""
    strong_buy: int = 0
    buy: int = 0
    hold: int = 0
    sell: int = 0
    strong_sell: int = 0
    consensus_score: Optional[float] = None


class StrategyData(BaseModel):
    """Target price and stop loss strategy"""
    target_price: Optional[float] = Field(None, description="AI target price")
    stop_loss: Optional[float] = Field(None, description="AI stop loss")
    risk_reward_ratio: Optional[float] = Field(None, description="Risk/reward ratio")
    analyst_consensus: Optional[AnalystConsensus] = Field(None, description="Analyst consensus data")
    analyst_ratings: Optional[List[AnalystRatingItem]] = Field(None, description="Individual analyst ratings")
    defense_lines: Optional[List[DefenseLine]] = Field(None, description="Moving average defense lines")
    recommendations: Optional[RecommendationsData] = Field(None, description="Analyst recommendations distribution")


class CompanyProfileData(BaseModel):
    """Company profile ingest data"""
    long_name: Optional[str] = None
    industry: Optional[str] = None
    website: Optional[str] = None
    country: Optional[str] = None
    employees: Optional[int] = None
    summary: Optional[str] = None


class KeyMetricsData(BaseModel):
    """Key metrics ingest data"""
    market_cap: Optional[float] = None
    pe: Optional[float] = None
    forward_pe: Optional[float] = None
    peg: Optional[float] = None
    pb: Optional[float] = None
    ps: Optional[float] = None
    ev_revenue: Optional[float] = None
    ev_ebitda: Optional[float] = None
    profit_margin: Optional[float] = None
    operating_margin: Optional[float] = None
    gross_margin: Optional[float] = None
    roe: Optional[float] = None
    roa: Optional[float] = None
    debt_to_equity: Optional[float] = None
    current_ratio: Optional[float] = None
    beta: Optional[float] = None
    dividend_yield: Optional[float] = None
    payout_ratio: Optional[float] = None
    earnings_growth: Optional[float] = None
    revenue_growth: Optional[float] = None


class FundamentalsData(BaseModel):
    """Fundamentals ingest wrapper"""
    profile: Optional[CompanyProfileData] = None
    metrics: Optional[KeyMetricsData] = None
    financials: Optional[dict] = None    # {latest_quarter, income, balance_sheet, cash_flow}
    dividends: Optional[dict] = None     # {recent: [{date, amount}], annual_total}


class OwnershipData(BaseModel):
    """기관/내부자/공매도 보유율 통합 객체"""
    institution: Optional[float] = Field(None, description="Institutional ownership %")
    insider: Optional[float] = Field(None, description="Insider ownership %")
    short_float: Optional[float] = Field(None, description="Short % of float")


class InstitutionalHolder(BaseModel):
    """개별 기관투자자 보유 현황"""
    holder: str = Field(..., description="Institution name")
    pct_held: Optional[float] = Field(None, description="Holding %")
    pct_change: Optional[float] = Field(None, description="Change in holding %")


class ExtendedItemIngest(BaseModel):
    """
    Extended payload format from Mac mini (nested structure).

    Supports nested objects: price, score, indicators, ai_analysis, trend, strategy, fundamentals
    """
    date: Date = Field(..., description="Data date")
    ticker: str = Field(..., max_length=10, description="Ticker symbol")
    name_en: Optional[str] = Field(None, max_length=200, description="English ticker name (e.g., 'Apple Inc.')")
    name_ko: Optional[str] = Field(None, max_length=200, description="Korean ticker name (e.g., '애플')")
    price: PriceData = Field(..., description="OHLCV price data")
    score: ScoreData = Field(..., description="Score and signal")
    indicators: IndicatorData = Field(..., description="Technical indicators")
    ai_analysis: AIAnalysisData = Field(..., description="AI analysis results")
    trend: Optional[TrendData] = Field(None, description="Trendline data with pre-calculated values")
    strategy: Optional[StrategyData] = Field(None, description="Target/stop strategy")
    sector: Optional[str] = Field(None, max_length=100, description="GICS sector name")
    sub_industry: Optional[str] = Field(None, max_length=200, description="GICS sub-industry name")
    market_data: Optional[MarketData] = Field(None, description="Daily market data (change_pct, trading_value)")
    fundamentals: Optional[FundamentalsData] = Field(None, description="Company fundamentals (profile, metrics, financials, dividends)")
    calendar: Optional[CalendarData] = Field(None, description="Calendar events (earnings date, dividends)")
    earnings_history: Optional[List[EarningsHistoryEntry]] = Field(None, description="Earnings history (EPS estimate vs reported)")
    ownership: Optional[OwnershipData] = Field(None, description="Ownership data (institution, insider, short_float)")
    institutional_holders: Optional[List[InstitutionalHolder]] = Field(None, description="Individual institutional holders")
    membership: Optional[List[str]] = Field(None, description="Index membership list (e.g., ['SP500', 'DOW30'])")


class SimpleItemIngest(BaseModel):
    """
    Simple flat payload format (backward compatibility).

    Supports flat structure like existing implementation.
    """
    date: Date = Field(..., description="Data date")
    ticker: str = Field(..., max_length=10, description="Ticker symbol")
    name_en: Optional[str] = Field(None, max_length=200, description="English ticker name (e.g., 'Apple Inc.')")
    name_ko: Optional[str] = Field(None, max_length=200, description="Korean ticker name (e.g., '애플')")
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
    mfi: Optional[float] = Field(None, description="MFI (0-100)")

    # Treemap fields (flat)
    sector: Optional[str] = Field(None, max_length=100, description="GICS sector name")
    sub_industry: Optional[str] = Field(None, max_length=200, description="GICS sub-industry name")
    change_pct: Optional[float] = Field(None, description="Daily price change %")
    trading_value: Optional[float] = Field(None, description="close * volume (USD)")

    # Index membership
    membership: Optional[List[str]] = Field(None, description="Index membership list (e.g., ['SP500', 'DOW30'])")


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


# ============================================================
# Treemap Response Schemas (섹터별 트리맵)
# ============================================================

class TreemapItem(BaseModel):
    """Individual ticker in treemap"""
    ticker: str = Field(..., description="Ticker symbol")
    name: Optional[str] = Field(None, description="Display name")
    sector: Optional[str] = Field(None, description="GICS sector")
    sub_industry: Optional[str] = Field(None, description="GICS sub-industry")
    change_pct: Optional[float] = Field(None, description="Daily price change %")
    trading_value: Optional[float] = Field(None, description="Trading value (close * volume, USD)")
    close: Optional[float] = Field(None, description="Close price")
    volume: Optional[int] = Field(None, description="Trading volume")
    score: Optional[float] = Field(None, description="AI score")
    signal: Optional[str] = Field(None, description="Trading signal")

    class Config:
        from_attributes = True


class TreemapSector(BaseModel):
    """Sector group in treemap"""
    sector: str = Field(..., description="GICS sector name")
    ticker_count: int = Field(..., description="Number of tickers in sector")
    avg_change_pct: Optional[float] = Field(None, description="Average change % in sector")
    total_trading_value: Optional[float] = Field(None, description="Total trading value in sector")
    items: List[TreemapItem] = Field(..., description="Tickers in this sector")


class TreemapResponse(BaseModel):
    """Treemap API response"""
    date: Date = Field(..., description="Data date")
    total_tickers: int = Field(..., description="Total number of tickers")
    sectors: List[TreemapSector] = Field(..., description="Sector groups")


# ============================================================
# Earnings Week Schemas (이번 주 실적 일정)
# ============================================================

class EarningsEstimateIngest(BaseModel):
    """EPS consensus estimates"""
    high: Optional[float] = None
    low: Optional[float] = None
    avg: Optional[float] = None


class EarningsWeekItem(BaseModel):
    """Single earnings event for weekly calendar ingest"""
    ticker: str
    week: str                                    # "this" | "next"
    name_ko: Optional[str] = None
    name_en: Optional[str] = None
    earnings_date: str
    earnings_date_end: Optional[str] = None
    earnings_confirmed: bool = False
    d_day: Optional[int] = None
    earnings_estimate: EarningsEstimateIngest = EarningsEstimateIngest()
    revenue_estimate: Optional[float] = None
    prev_surprise_pct: Optional[float] = None
    score: Optional[float] = None


class EarningsWeekIngestPayload(BaseModel):
    """Earnings week ingest payload from Mac mini"""
    date: str
    week_start: str
    week_end: str
    events: List[EarningsWeekItem]


class EarningsWeekEventResponse(BaseModel):
    """Single earnings event in API response"""
    ticker: str
    week: str
    name_ko: Optional[str] = None
    name_en: Optional[str] = None
    earnings_date: str
    earnings_date_end: Optional[str] = None
    earnings_confirmed: bool = False
    d_day: Optional[int] = None
    eps_estimate_high: Optional[float] = None
    eps_estimate_low: Optional[float] = None
    eps_estimate_avg: Optional[float] = None
    revenue_estimate: Optional[float] = None
    prev_surprise_pct: Optional[float] = None
    score: Optional[float] = None


class EarningsUpcomingResponse(BaseModel):
    """Upcoming earnings API response (grouped by date)"""
    week_start: str
    week_end: str
    total_count: int
    by_date: Dict[str, List[EarningsWeekEventResponse]]


# ============================================================
# News Schemas (뉴스 인제스트 & 조회)
# ============================================================

class FutureEventData(BaseModel):
    """Future event nested object within news item"""
    date: Optional[str] = Field(None, description="Expected event date (YYYY-MM-DD)")
    description: Optional[str] = Field(None, description="Event description")


class NewsItemIngest(BaseModel):
    """Single news item for ingest from Mac mini"""
    date: Date = Field(..., description="News collection date")
    ticker: str = Field(..., max_length=10, description="Ticker symbol")
    title: str = Field(..., max_length=512, description="News headline")
    source: Optional[str] = Field(None, max_length=100, description="News source name")
    source_url: Optional[str] = Field(None, max_length=2048, description="Original article URL")
    published_at: DateTime = Field(..., description="Article publication datetime")
    ai_summary: str = Field(..., max_length=200, description="AI-generated summary")
    sentiment_score: int = Field(..., ge=-100, le=100, description="Sentiment score (-100 ~ +100)")
    sentiment_grade: Literal["bullish", "neutral", "bearish"] = Field(..., description="Sentiment grade")
    sentiment_label: Literal["호재", "중립", "악재"] = Field(..., description="Korean sentiment label")
    future_event: Optional[FutureEventData] = Field(None, description="Upcoming event related to this news")


class NewsIngestPayload(BaseModel):
    """News ingest payload from Mac mini"""
    items: List[NewsItemIngest] = Field(..., description="List of news items")


class NewsIngestResponse(BaseModel):
    """News ingest response"""
    upserted: int = Field(..., description="Number of items upserted")
    total: int = Field(..., description="Total items in payload")


class NewsListResponse(BaseModel):
    """News list API response"""
    items: List[NewsItemResponse] = Field(default_factory=list)
    total: int = 0


class NewsSummaryResponse(BaseModel):
    """News sentiment summary for a ticker"""
    ticker: str
    date: Optional[Date] = None
    total_articles: int = 0
    bullish: int = 0
    neutral: int = 0
    bearish: int = 0
    avg_score: Optional[float] = None

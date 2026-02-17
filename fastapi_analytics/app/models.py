from sqlalchemy import Column, String, Date, Float, BigInteger, Integer, Boolean, TIMESTAMP, text
from sqlalchemy.dialects.postgresql import JSONB
from app.database import Base


class TickerScore(Base):
    """
    Ticker daily scores for mobile app consumption.

    **Serving Layer** - Read-only for FastAPI
    Mac mini uploads daily calculated scores here.

    MVP Fields:
    - ticker: Stock symbol or ticker name
    - date: Score calculation date
    - score: Calculated score value
    - signal: Trading signal (BUY/SELL/HOLD)
    """
    __tablename__ = "ticker_scores"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(50), primary_key=True, index=True)
    date = Column(Date, primary_key=True, index=True)
    score = Column(Float, nullable=False)
    signal = Column(String(20))  # BUY, SELL, HOLD (supports Korean signals)
    calculated_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class Ticker(Base):
    """
    Ticker metadata (symbol, name, category).

    **Metadata Layer** - For search and display
    Provides human-readable names and categorization.
    """
    __tablename__ = "tickers"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(50), primary_key=True, index=True)
    ticker_type = Column(String(50))  # For backward compatibility
    ticker_name = Column(String(200), index=True)  # Searchable name
    name = Column(String(200))  # Display name
    category = Column(String(50))  # Category/sector
    sector = Column(String(100))  # GICS sector
    sub_industry = Column(String(200))  # GICS sub-industry
    extra_data = Column("metadata", JSONB)  # Additional JSON data


class TickerPrice(Base):
    """
    Ticker daily OHLCV price data for charting.

    **Price Layer** - Read-only for FastAPI
    Mac mini uploads daily price data here.

    Fields:
    - ticker: Stock symbol
    - date: Price data date
    - open/high/low/close: OHLC prices
    - volume: Trading volume
    """
    __tablename__ = "ticker_prices"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    date = Column(Date, primary_key=True, index=True)
    open = Column(Float)
    high = Column(Float)
    low = Column(Float)
    close = Column(Float)
    volume = Column(BigInteger)
    change_pct = Column(Float)  # Daily price change %
    trading_value = Column(Float)  # close * volume (USD)
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class TickerIndicator(Base):
    """
    Technical indicators (RSI, MFI, MACD, Bollinger Bands).

    **Indicator Layer** - Read-only for FastAPI
    Mac mini uploads calculated indicators here.

    Fields:
    - ticker: Stock symbol
    - date: Indicator calculation date
    - rsi: Relative Strength Index (0-100)
    - mfi: Money Flow Index (0-100, volume-weighted RSI)
    - macd: MACD line value
    - macd_signal: MACD signal line
    - macd_hist: MACD histogram
    - bb_width: Bollinger Band width
    - bb_upper/lower/middle: Bollinger Band levels
    """
    __tablename__ = "ticker_indicators"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    date = Column(Date, primary_key=True, index=True)
    rsi = Column(Float)
    macd = Column(Float)
    macd_signal = Column(Float)
    macd_hist = Column(Float)
    bb_width = Column(Float)
    bb_upper = Column(Float)
    bb_lower = Column(Float)
    bb_middle = Column(Float)
    mfi = Column(Float)  # Money Flow Index (0-100)
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class TickerTarget(Base):
    """
    Target price and stop loss levels.

    **Target Layer** - Read-only for FastAPI
    Mac mini uploads AI-calculated targets here.

    Fields:
    - ticker: Stock symbol
    - date: Target calculation date
    - target_price: AI-calculated target price
    - stop_loss: AI-calculated stop loss level
    - risk_reward_ratio: R/R ratio
    """
    __tablename__ = "ticker_targets"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    date = Column(Date, primary_key=True, index=True)
    target_price = Column(Float)
    stop_loss = Column(Float)
    risk_reward_ratio = Column(Float)
    analyst_target_mean = Column(Float)
    analyst_target_high = Column(Float)
    analyst_target_low = Column(Float)
    analyst_count = Column(Integer)
    recommendation = Column(String(20))
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class TickerTrendline(Base):
    """
    Trendline coefficients for chart rendering.

    **Trendline Layer** - Read-only for FastAPI
    Mac mini uploads calculated trendline parameters here.

    Fields:
    - ticker: Stock symbol
    - date: Trendline calculation date
    - high_slope/intercept: High price trendline (y = mx + b)
    - low_slope/intercept: Low price trendline
    - high_r_squared/low_r_squared: R² coefficients (reliability)
    - trend_period_days: Calculation period (default 30)
    """
    __tablename__ = "ticker_trendlines"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    date = Column(Date, primary_key=True, index=True)
    high_slope = Column(Float)
    high_intercept = Column(Float)
    high_r_squared = Column(Float)
    low_slope = Column(Float)
    low_intercept = Column(Float)
    low_r_squared = Column(Float)
    trend_period_days = Column(Integer, default=30)
    high_values = Column(JSONB)  # Pre-calculated y-values: [{"date": "2024-10-20", "y": 148.20}, ...]
    low_values = Column(JSONB)   # Pre-calculated y-values: [{"date": "2024-10-20", "y": 130.15}, ...]
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class TickerInstitution(Base):
    """
    Institutional and foreign ownership data.

    **Institution Layer** - Read-only for FastAPI
    Mac mini uploads ownership change data here.

    Fields:
    - ticker: Stock symbol
    - date: Ownership data date
    - inst_ownership: Institutional ownership %
    - foreign_ownership: Foreign ownership %
    - inst_chg_*: Institutional ownership changes (1d/5d/15d/30d)
    - foreign_chg_*: Foreign ownership changes (1d/5d/15d/30d)
    """
    __tablename__ = "ticker_institutions"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    date = Column(Date, primary_key=True, index=True)
    inst_ownership = Column(Float)
    foreign_ownership = Column(Float)
    insider_ownership = Column(Float)  # Insider ownership %
    inst_chg_1d = Column(Float)
    inst_chg_5d = Column(Float)
    inst_chg_15d = Column(Float)
    inst_chg_30d = Column(Float)
    foreign_chg_1d = Column(Float)
    foreign_chg_5d = Column(Float)
    foreign_chg_15d = Column(Float)
    foreign_chg_30d = Column(Float)
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class TickerShort(Base):
    """
    Short selling metrics.

    **Short Layer** - Read-only for FastAPI
    Mac mini uploads short selling data here.

    Fields:
    - ticker: Stock symbol
    - date: Short data date
    - short_ratio: Days to cover (short interest / avg volume)
    - short_percent_float: Short % of float
    - short_percent_shares: Short % of shares outstanding
    - short_interest: Absolute shares shorted
    """
    __tablename__ = "ticker_shorts"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    date = Column(Date, primary_key=True, index=True)
    short_ratio = Column(Float)
    short_percent_float = Column(Float)
    short_percent_shares = Column(Float)
    short_interest = Column(BigInteger)
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class TickerAIAnalysis(Base):
    """
    AI-generated analysis and predictions.

    **AI Analysis Layer** - Read-only for FastAPI
    Mac mini uploads AI analysis results here.

    Fields:
    - ticker: Stock symbol
    - date: Analysis date
    - probability: Prediction confidence (0.0-1.0)
    - summary: Brief analysis summary (max 200 chars)
    - bullish_reasons: List of bullish factors (JSONB array)
    - bearish_reasons: List of bearish factors (JSONB array)
    - final_comment: Final recommendation (max 500 chars)
    """
    __tablename__ = "ticker_ai_analysis"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    date = Column(Date, primary_key=True, index=True)
    probability = Column(Float, nullable=False)
    summary = Column(String(200), nullable=False)
    bullish_reasons = Column(JSONB)  # Array of strings
    bearish_reasons = Column(JSONB)  # Array of strings
    final_comment = Column(String(500))
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class CompanyProfile(Base):
    """
    Company profile data (one row per ticker, non-time-series).

    **Profile Layer** - Read-only for FastAPI
    Mac mini uploads company fundamentals from yfinance here.
    """
    __tablename__ = "company_profile"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    long_name = Column(String(255))
    industry = Column(String(100))
    website = Column(String(255))
    country = Column(String(50))
    employees = Column(Integer)
    summary = Column(String)
    updated_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class TickerKeyMetrics(Base):
    """
    Key valuation and financial metrics (daily time-series).

    **Metrics Layer** - Read-only for FastAPI
    Mac mini uploads daily fundamental metrics from yfinance here.
    """
    __tablename__ = "ticker_key_metrics"
    __table_args__ = {'schema': 'analytics'}

    date = Column(Date, primary_key=True, index=True)
    ticker = Column(String(10), primary_key=True, index=True)
    market_cap = Column(Float)
    pe = Column(Float)
    forward_pe = Column(Float)
    peg = Column(Float)
    pb = Column(Float)
    ps = Column(Float)
    ev_revenue = Column(Float)
    ev_ebitda = Column(Float)
    profit_margin = Column(Float)
    operating_margin = Column(Float)
    gross_margin = Column(Float)
    roe = Column(Float)
    roa = Column(Float)
    debt_to_equity = Column(Float)
    current_ratio = Column(Float)
    beta = Column(Float)
    dividend_yield = Column(Float)
    payout_ratio = Column(Float)
    earnings_growth = Column(Float)
    revenue_growth = Column(Float)
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class TickerFinancials(Base):
    """
    Financial statements stored as JSONB (one row per ticker).

    **Financials Layer** - Read-only for FastAPI
    Mac mini uploads income/balance_sheet/cash_flow from yfinance here.
    """
    __tablename__ = "ticker_financials"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    latest_quarter = Column(String(10))
    income = Column(JSONB)
    balance_sheet = Column(JSONB)
    cash_flow = Column(JSONB)
    updated_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class TickerDividend(Base):
    """
    Dividend history (ticker + ex_date composite key).

    **Dividend Layer** - Read-only for FastAPI
    Mac mini uploads dividend history from yfinance here.
    """
    __tablename__ = "ticker_dividends"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    ex_date = Column(Date, primary_key=True)
    amount = Column(Float)


class TickerAnalystRating(Base):
    """
    Individual analyst ratings from financial institutions (finvizfinance).

    **Analyst Rating Layer** - Read-only for FastAPI
    Mac mini uploads institutional analyst ratings here.

    Fields:
    - ticker: Stock symbol
    - date: Data upload date (score date)
    - rating_date: Report publication date
    - firm: Institution name (e.g., 'Barclays', 'Morgan Stanley')
    - status: Rating change type (Upgrade/Downgrade/Reiterated/Initiated)
    - rating: Investment opinion (Overweight/Equal-Weight/Buy/Hold/Sell)
    - target_from: Previous target price
    - target_to: New target price
    """
    __tablename__ = "ticker_analyst_ratings"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    date = Column(Date, primary_key=True, index=True)
    rating_date = Column(Date, primary_key=True)
    firm = Column(String(100), primary_key=True)
    status = Column(String(30))
    rating = Column(String(50))
    target_from = Column(Float)
    target_to = Column(Float)
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class MacroIndicator(Base):
    """Macro economic indicators from FRED + signals (yield_curve, m2_liquidity)."""
    __tablename__ = "macro_indicators"
    __table_args__ = {'schema': 'analytics'}

    date = Column(Date, primary_key=True)
    indicator_code = Column(String(30), primary_key=True)
    indicator_name = Column(String(100))
    observation_date = Column(Date)
    value = Column(Float, nullable=False)
    previous_value = Column(Float)
    change_pct = Column(Float)
    source = Column(String(30))
    risk_level = Column(String(20))       # CRITICAL/WARNING/NORMAL (시장레이더)
    signal_message = Column(String)       # 한국어 설명 메시지
    liquidity_status = Column(String(20)) # EXPANDING/CONTRACTING/NEUTRAL (머니프린팅)
    updated_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class MacroChartData(Base):
    """Macro chart time-series data (t10y2y, m2_growth etc.)."""
    __tablename__ = "macro_chart_data"
    __table_args__ = {'schema': 'analytics'}

    series_id = Column(String(30), primary_key=True)  # t10y2y, m2_growth
    date = Column(Date, primary_key=True)
    value = Column(Float, nullable=False)
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class TickerCalendar(Base):
    """Ticker calendar events (earnings date, dividends)."""
    __tablename__ = "ticker_calendar"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    date = Column(Date, primary_key=True, index=True)
    next_earnings_date = Column(Date)
    next_earnings_date_end = Column(Date)
    earnings_confirmed = Column(Boolean, default=False)
    d_day = Column(Integer)
    ex_dividend_date = Column(Date)
    dividend_date = Column(Date)
    earnings_high = Column(Float)
    earnings_low = Column(Float)
    earnings_avg = Column(Float)
    revenue_high = Column(Float)
    revenue_low = Column(Float)
    revenue_avg = Column(Float)
    updated_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class TickerEarningsHistory(Base):
    """Ticker earnings history (EPS estimate vs reported)."""
    __tablename__ = "ticker_earnings_history"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    earnings_date = Column(Date, primary_key=True)
    eps_estimate = Column(Float)
    reported_eps = Column(Float)
    surprise_pct = Column(Float)
    updated_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class TickerDefenseLine(Base):
    """이동평균 방어선 (period별 MA 가격)."""
    __tablename__ = "ticker_defense_lines"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    date = Column(Date, primary_key=True, index=True)
    period = Column(Integer, primary_key=True)  # 20, 50, 200 etc.
    price = Column(Float, nullable=False)
    label = Column(String(20))
    distance_pct = Column(Float)
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class TickerRecommendation(Base):
    """애널리스트 의견분포 (strong_buy ~ strong_sell)."""
    __tablename__ = "ticker_recommendations"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    date = Column(Date, primary_key=True, index=True)
    strong_buy = Column(Integer, default=0)
    buy = Column(Integer, default=0)
    hold = Column(Integer, default=0)
    sell = Column(Integer, default=0)
    strong_sell = Column(Integer, default=0)
    consensus_score = Column(Float)
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class TickerInstitutionalHolder(Base):
    """개별 기관투자자 보유 현황."""
    __tablename__ = "ticker_institutional_holders"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    date = Column(Date, primary_key=True, index=True)
    holder = Column(String(100), primary_key=True)
    pct_held = Column(Float)
    pct_change = Column(Float)
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))


class EarningsWeekEvent(Base):
    """이번 주 실적 발표 일정 (Flutter 캘린더용)."""
    __tablename__ = "earnings_week_events"
    __table_args__ = {'schema': 'analytics'}

    ticker = Column(String(10), primary_key=True, index=True)
    earnings_date = Column(Date, primary_key=True)
    week = Column(String(10))                  # "this" | "next"
    name_ko = Column(String(100))
    name_en = Column(String(100))
    earnings_date_end = Column(Date)
    earnings_confirmed = Column(Boolean, server_default=text('FALSE'))
    d_day = Column(Integer)
    eps_estimate_high = Column(Float)
    eps_estimate_low = Column(Float)
    eps_estimate_avg = Column(Float)
    revenue_estimate = Column(Float)
    prev_surprise_pct = Column(Float)
    score = Column(Float)
    updated_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))

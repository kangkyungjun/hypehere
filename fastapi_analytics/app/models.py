from sqlalchemy import Column, String, Date, Float, BigInteger, Integer, TIMESTAMP, text
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
    Technical indicators (RSI, MACD, Bollinger Bands).

    **Indicator Layer** - Read-only for FastAPI
    Mac mini uploads calculated indicators here.

    Fields:
    - ticker: Stock symbol
    - date: Indicator calculation date
    - rsi: Relative Strength Index (0-100)
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

from sqlalchemy import Column, String, Date, Float, BigInteger, TIMESTAMP, text
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
    signal = Column(String(10))  # BUY, SELL, HOLD
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
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))

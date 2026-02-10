"""
Trading Calendar Utilities for US Stock Market

Provides functions to validate trading days and exclude weekends/holidays.
"""
from datetime import date, timedelta
from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models import TickerScore


# US Stock Market Holidays for 2026
US_MARKET_HOLIDAYS_2026 = {
    date(2026, 1, 1),   # New Year's Day
    date(2026, 1, 19),  # Martin Luther King Jr. Day
    date(2026, 2, 16),  # Presidents' Day
    date(2026, 4, 3),   # Good Friday
    date(2026, 5, 25),  # Memorial Day
    date(2026, 7, 3),   # Independence Day (observed)
    date(2026, 9, 7),   # Labor Day
    date(2026, 11, 26), # Thanksgiving Day
    date(2026, 12, 25), # Christmas Day
}

# US Stock Market Holidays for 2025
US_MARKET_HOLIDAYS_2025 = {
    date(2025, 1, 1),   # New Year's Day
    date(2025, 1, 20),  # Martin Luther King Jr. Day
    date(2025, 2, 17),  # Presidents' Day
    date(2025, 4, 18),  # Good Friday
    date(2025, 5, 26),  # Memorial Day
    date(2025, 7, 4),   # Independence Day
    date(2025, 9, 1),   # Labor Day
    date(2025, 11, 27), # Thanksgiving Day
    date(2025, 12, 25), # Christmas Day
}

# Combined holidays dictionary
US_MARKET_HOLIDAYS = US_MARKET_HOLIDAYS_2025 | US_MARKET_HOLIDAYS_2026


def is_trading_day(check_date: date) -> bool:
    """
    Check if a given date is a valid US stock market trading day.

    Returns False for:
    - Weekends (Saturday/Sunday)
    - US stock market holidays

    Args:
        check_date: Date to check

    Returns:
        bool: True if trading day, False otherwise

    Example:
        >>> is_trading_day(date(2026, 2, 7))  # Saturday
        False
        >>> is_trading_day(date(2026, 2, 6))  # Friday (trading day)
        True
        >>> is_trading_day(date(2026, 1, 1))  # New Year's Day
        False
    """
    # Check if weekend (Saturday = 5, Sunday = 6)
    if check_date.weekday() >= 5:
        return False

    # Check if US market holiday
    if check_date in US_MARKET_HOLIDAYS:
        return False

    return True


def get_latest_trading_date(db: Session, check_all_tables: bool = False) -> Optional[date]:
    """
    Get the most recent trading day from the database.

    Queries the database for the latest date with ticker data,
    then walks backward to find the most recent valid trading day
    (skipping weekends and holidays).

    Args:
        db: SQLAlchemy database session
        check_all_tables: If True, checks ticker_prices, ticker_scores, and ticker_indicators
                         to find the maximum date across all tables. If False, only checks
                         ticker_scores (default behavior for backward compatibility).

    Returns:
        date: Most recent trading day with data, or None if no data exists

    Example:
        If DB has data for 2026-02-07 (Saturday), this will return 2026-02-06 (Friday)
    """
    # Import models at function scope (needed for both if/else branches)
    from app.models import TickerPrice, TickerScore, TickerIndicator

    # Get latest date from database
    if check_all_tables:
        # ⭐ Phase 3: Check ALL tables to prevent data loss when tables have different latest dates
        latest_price = db.query(func.max(TickerPrice.date)).scalar()
        latest_score = db.query(func.max(TickerScore.date)).scalar()
        latest_indicator = db.query(func.max(TickerIndicator.date)).scalar()

        # Get maximum date across all tables
        all_dates = [d for d in [latest_price, latest_score, latest_indicator] if d is not None]
        if not all_dates:
            return None

        latest_date = max(all_dates)
    else:
        # Default behavior: only check ticker_scores (backward compatibility)
        latest_date = db.query(func.max(TickerScore.date)).scalar()

    if latest_date is None:
        return None

    # Walk backward until we find a valid trading day
    # Limit to 10 days back to prevent infinite loop
    max_lookback = 10
    attempts = 0

    while attempts < max_lookback:
        if is_trading_day(latest_date):
            return latest_date

        # Move back one day
        latest_date -= timedelta(days=1)
        attempts += 1

    # If we couldn't find a trading day in 10 days, return None
    return None


def get_previous_trading_day(from_date: date, days_back: int = 1) -> date:
    """
    Get the Nth previous trading day from a given date.

    Args:
        from_date: Starting date
        days_back: Number of trading days to go back (default: 1)

    Returns:
        date: The Nth previous trading day

    Example:
        >>> get_previous_trading_day(date(2026, 2, 9), 1)  # Monday
        date(2026, 2, 6)  # Friday (skips weekend)
    """
    current_date = from_date
    trading_days_found = 0

    # Limit to 30 calendar days to prevent infinite loop
    max_attempts = 30
    attempts = 0

    while trading_days_found < days_back and attempts < max_attempts:
        current_date -= timedelta(days=1)
        attempts += 1

        if is_trading_day(current_date):
            trading_days_found += 1

    return current_date

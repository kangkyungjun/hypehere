"""Server-side staleness judgement (S2).

Why the server decides: the app does not know the market's latest trading
date. The alternative it could reach for -- compare this ticker's date against
some other ticker's (an index, say) -- breaks the moment a supply outage puts
only part of the universe a day behind. That happened on 2026-10-01. The app
would then stamp "stale" on healthy tickers, which is worse than saying
nothing.

The server knows every ticker's latest date, so it answers directly.
"""
from datetime import date
from typing import Optional

from app.utils.trading_calendar import trading_days_between


# A ticker one trading day behind the market is NOT flagged.
#
# Per-ticker dates legitimately differ: the pipeline's own spec says so, and on
# 2026-10-01 a supply outage left part of the universe a day late while the
# data was perfectly good. Flagging at 1 would light up healthy tickers on any
# partial-load day, and a badge that cries wolf gets ignored.
#
# 2 trading days survives that routine lag and still catches anything
# genuinely behind -- a delisted ticker is tens of trading days out.
STALE_TRADING_DAYS = 2


def freshness_payload(
    ticker_latest: Optional[date],
    market_latest: Optional[date],
) -> Optional[dict]:
    """Build the freshness block for a ticker.

    Returns None when either date is unknown -- with nothing to compare, the
    honest answer is to omit the field rather than guess `stale: false` and
    have the app render a freshness claim the server did not make.
    """
    if ticker_latest is None or market_latest is None:
        return None

    behind = trading_days_between(ticker_latest, market_latest)
    return {
        'as_of': ticker_latest,
        'market_as_of': market_latest,
        'trading_days_behind': behind,
        'stale': behind >= STALE_TRADING_DAYS,
        'stale_threshold': STALE_TRADING_DAYS,
    }

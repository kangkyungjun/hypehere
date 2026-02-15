from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from datetime import date
from typing import Optional
from collections import defaultdict

from app.database import get_db
from app.models import TickerPrice, Ticker, TickerScore
from app.schemas import TreemapResponse, TreemapSector, TreemapItem

router = APIRouter()


@router.get("/treemap", response_model=TreemapResponse)
def get_treemap(
    target_date: Optional[date] = Query(None, alias="date", description="Target date (default: latest available)"),
    sector: Optional[str] = Query(None, description="Filter by sector name"),
    limit: int = Query(500, ge=1, le=2000, description="Max tickers to return"),
    db: Session = Depends(get_db),
):
    """
    Treemap data for S&P 500 sector visualization.

    Returns tickers grouped by GICS sector with change_pct and trading_value
    for Flutter treemap chart rendering.
    """
    # Determine target date: use provided or find latest available
    if target_date is None:
        latest = (
            db.query(func.max(TickerPrice.date))
            .filter(TickerPrice.trading_value.isnot(None))
            .scalar()
        )
        if latest is None:
            # Fallback: latest date with any price data
            latest = db.query(func.max(TickerPrice.date)).scalar()
        if latest is None:
            return TreemapResponse(date=date.today(), total_tickers=0, sectors=[])
        target_date = latest

    # Query: ticker_prices LEFT JOIN tickers LEFT JOIN ticker_scores
    query = (
        db.query(
            TickerPrice.ticker,
            TickerPrice.close,
            TickerPrice.volume,
            TickerPrice.change_pct,
            TickerPrice.trading_value,
            Ticker.name,
            Ticker.sector,
            Ticker.sub_industry,
            TickerScore.score,
            TickerScore.signal,
        )
        .outerjoin(Ticker, TickerPrice.ticker == Ticker.ticker)
        .outerjoin(
            TickerScore,
            (TickerPrice.ticker == TickerScore.ticker) & (TickerPrice.date == TickerScore.date),
        )
        .filter(TickerPrice.date == target_date)
    )

    # Optional sector filter
    if sector:
        query = query.filter(Ticker.sector == sector)

    # Order by trading_value DESC, limit results
    query = query.order_by(desc(TickerPrice.trading_value)).limit(limit)

    rows = query.all()

    # Group by sector in Python
    sector_map = defaultdict(list)
    for row in rows:
        sector_name = row.sector or "Unknown"
        sector_map[sector_name].append(
            TreemapItem(
                ticker=row.ticker,
                name=row.name,
                sector=row.sector,
                sub_industry=row.sub_industry,
                change_pct=row.change_pct,
                trading_value=row.trading_value,
                close=row.close,
                volume=row.volume,
                score=row.score,
                signal=row.signal,
            )
        )

    # Build sector summaries
    sectors = []
    for sector_name, items in sorted(sector_map.items()):
        change_values = [i.change_pct for i in items if i.change_pct is not None]
        trading_values = [i.trading_value for i in items if i.trading_value is not None]

        sectors.append(
            TreemapSector(
                sector=sector_name,
                ticker_count=len(items),
                avg_change_pct=sum(change_values) / len(change_values) if change_values else None,
                total_trading_value=sum(trading_values) if trading_values else None,
                items=items,
            )
        )

    total_tickers = sum(s.ticker_count for s in sectors)

    return TreemapResponse(
        date=target_date,
        total_tickers=total_tickers,
        sectors=sectors,
    )

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from datetime import date
from typing import Optional
from collections import defaultdict

from app.database import get_db
from app.models import TickerPrice, Ticker, TickerScore, MarketIndex, MarketIndexChart, StockMembership
from app.schemas import (
    TreemapResponse, TreemapSector, TreemapItem,
    MarketIndicesResponse, MarketIndexResponse, IndexChartPoint,
)

router = APIRouter()


@router.get("/treemap", response_model=TreemapResponse)
def get_treemap(
    target_date: Optional[date] = Query(None, alias="date", description="Target date (default: latest available)"),
    sector: Optional[str] = Query(None, description="Filter by sector name"),
    index: Optional[str] = Query(None, description="Filter by index: SP500, DOW30, NASDAQ100"),
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

    # Optional index filter
    if index:
        query = query.join(
            StockMembership,
            (TickerPrice.ticker == StockMembership.ticker) &
            (StockMembership.index_code == index)
        )

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


@router.get("/indices", response_model=MarketIndicesResponse)
def get_market_indices(
    target_date: Optional[date] = Query(None, alias="date", description="Target date (default: latest)"),
    db: Session = Depends(get_db),
):
    """
    3대 시장 지수 조회 (Flutter 대시보드용).

    SPY (S&P 500), QQQ (NASDAQ 100), DIA (Dow Jones)의
    종가, 전일대비 변동률, 스파크라인 차트 데이터를 반환.
    """
    # 날짜 결정 (미지정 시 최신)
    if target_date is None:
        target_date = db.query(func.max(MarketIndex.date)).scalar()
    if target_date is None:
        return MarketIndicesResponse(date=str(date.today()), indices=[])

    # 해당 날짜의 지수 데이터 조회
    rows = db.query(MarketIndex).filter(
        MarketIndex.date == target_date,
    ).order_by(MarketIndex.code).all()

    if not rows:
        return MarketIndicesResponse(date=str(target_date), indices=[])

    # 각 지수별 차트 데이터 조회
    indices = []
    for row in rows:
        chart_rows = db.query(MarketIndexChart).filter(
            MarketIndexChart.code == row.code,
        ).order_by(MarketIndexChart.date).all()

        indices.append(MarketIndexResponse(
            code=row.code, name=row.name,
            close=row.close, prev_close=row.prev_close,
            change=row.change, change_pct=row.change_pct,
            open=row.open, high=row.high, low=row.low,
            volume=row.volume,
            chart=[IndexChartPoint(date=str(c.date), close=c.close)
                   for c in chart_rows],
        ))

    return MarketIndicesResponse(date=str(target_date), indices=indices)

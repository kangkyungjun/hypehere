from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from datetime import date
from typing import Optional, List
from collections import defaultdict

from app.database import get_db
from app.models import TickerPrice, Ticker, TickerScore, MarketIndex, MarketIndexChart, StockMembership, StockClassification, TickerKeyMetrics
from app.schemas import (
    TreemapResponse, TreemapSector, TreemapItem,
    MarketIndicesResponse, MarketIndexResponse, IndexChartPoint,
    ClassificationResponse, TopTickerResponse,
)
from app.routers.scores import translate_signal

router = APIRouter()

# ETF name detection keywords (for tickers with NULL sector)
_ETF_NAME_KEYWORDS = (
    'ETF', 'FUND', 'TRUST',
    'PROSHARES', 'DIREXION', 'ISHARES', 'SPDR',
    'VANGUARD', 'VANECK', 'GLOBAL X', 'KRANESHARES',
    'STATE STREET', 'INVESCO', 'SCHWAB', 'AMPLIFY', 'JPMORGAN',
)


def _detect_sector(sector: str | None, name: str | None) -> str:
    # Always check ETF keywords in name first (even if sector exists)
    if name:
        name_upper = name.upper()
        if any(kw in name_upper for kw in _ETF_NAME_KEYWORDS):
            return "ETF"
    if sector:
        return sector
    return "Unknown"


@router.get("/treemap", response_model=TreemapResponse)
def get_treemap(
    target_date: Optional[date] = Query(None, alias="date", description="Target date (default: latest available)"),
    sector: Optional[str] = Query(None, description="Filter by sector name"),
    index: Optional[str] = Query(None, description="Filter by index: SP500, DOW30, NASDAQ100"),
    classification: Optional[str] = Query(None, description="Filter by classification: FAST_GROWER, STALWART, etc."),
    limit: int = Query(500, ge=1, le=2000, description="Max tickers to return"),
    exclude_etf: bool = Query(True, description="Exclude ETF sector from results"),
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
            Ticker.extra_data,
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

    # Optional classification filter (Peter Lynch)
    if classification:
        # Subquery: latest classification per ticker
        cls_subq = (
            db.query(
                StockClassification.ticker,
                func.max(StockClassification.date).label("max_date"),
            )
            .group_by(StockClassification.ticker)
            .subquery()
        )
        query = query.join(
            StockClassification,
            (TickerPrice.ticker == StockClassification.ticker),
        ).join(
            cls_subq,
            (StockClassification.ticker == cls_subq.c.ticker) &
            (StockClassification.date == cls_subq.c.max_date),
        ).filter(StockClassification.category == classification.upper())

    # Order by trading_value DESC, limit results
    query = query.order_by(desc(TickerPrice.trading_value)).limit(limit)

    rows = query.all()

    # Group by sector in Python
    sector_map = defaultdict(list)
    for row in rows:
        sector_name = _detect_sector(row.sector, row.name)
        if exclude_etf and sector_name == "ETF":
            continue
        name_ko = (row.extra_data or {}).get('name_ko') if row.extra_data else None
        sector_map[sector_name].append(
            TreemapItem(
                ticker=row.ticker,
                name=row.name,
                name_ko=name_ko,
                sector=sector_name,
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


@router.get("/classifications/summary")
def get_classification_summary(
    db: Session = Depends(get_db),
):
    """
    카테고리별 종목 수 요약 (Peter Lynch 6-category).

    Returns: {"FAST_GROWER": 120, "STALWART": 95, ...}
    """
    from sqlalchemy import distinct

    # Get latest date per ticker (subquery)
    from sqlalchemy.orm import aliased
    subq = (
        db.query(
            StockClassification.ticker,
            func.max(StockClassification.date).label("max_date"),
        )
        .group_by(StockClassification.ticker)
        .subquery()
    )

    rows = (
        db.query(StockClassification.category, func.count())
        .join(
            subq,
            (StockClassification.ticker == subq.c.ticker) &
            (StockClassification.date == subq.c.max_date),
        )
        .group_by(StockClassification.category)
        .all()
    )

    return {category: count for category, count in rows}


@router.get("/classifications/stocks")
def get_stocks_by_classification(
    category: str = Query(..., description="Classification category (e.g., FAST_GROWER)"),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
):
    """
    특정 분류의 종목 목록 조회.

    Returns: list of {ticker, name, name_ko, category_ko, category_en, confidence, score, change_pct}
    """
    # Latest classification per ticker
    subq = (
        db.query(
            StockClassification.ticker,
            func.max(StockClassification.date).label("max_date"),
        )
        .group_by(StockClassification.ticker)
        .subquery()
    )

    # Latest score per ticker (independent of classification date)
    score_subq = (
        db.query(
            TickerScore.ticker,
            func.max(TickerScore.date).label("max_date"),
        )
        .group_by(TickerScore.ticker)
        .subquery()
    )

    # Latest price per ticker (independent of classification date)
    price_subq = (
        db.query(
            TickerPrice.ticker,
            func.max(TickerPrice.date).label("max_date"),
        )
        .group_by(TickerPrice.ticker)
        .subquery()
    )

    rows = (
        db.query(
            StockClassification.ticker,
            StockClassification.category,
            StockClassification.category_ko,
            StockClassification.category_en,
            StockClassification.confidence,
            Ticker.name,
            Ticker.extra_data,
            TickerScore.score,
            TickerScore.signal,
            TickerPrice.change_pct,
            TickerPrice.close,
        )
        .join(
            subq,
            (StockClassification.ticker == subq.c.ticker) &
            (StockClassification.date == subq.c.max_date),
        )
        .outerjoin(Ticker, StockClassification.ticker == Ticker.ticker)
        .outerjoin(
            score_subq,
            StockClassification.ticker == score_subq.c.ticker,
        )
        .outerjoin(
            TickerScore,
            (StockClassification.ticker == TickerScore.ticker) &
            (TickerScore.date == score_subq.c.max_date),
        )
        .outerjoin(
            price_subq,
            StockClassification.ticker == price_subq.c.ticker,
        )
        .outerjoin(
            TickerPrice,
            (StockClassification.ticker == TickerPrice.ticker) &
            (TickerPrice.date == price_subq.c.max_date),
        )
        .filter(StockClassification.category == category.upper())
        .order_by(desc(StockClassification.confidence))
        .limit(limit)
        .all()
    )

    results = []
    for row in rows:
        name_ko = (row.extra_data or {}).get('name_ko') if row.extra_data else None
        results.append({
            "ticker": row.ticker,
            "name": row.name,
            "name_ko": name_ko,
            "category": row.category,
            "category_ko": row.category_ko,
            "category_en": row.category_en,
            "confidence": row.confidence,
            "score": row.score,
            "signal": row.signal,
            "change_pct": row.change_pct,
            "close": row.close,
        })

    return results

@router.get("/top-marketcap", response_model=List[TopTickerResponse])
def get_top_by_marketcap(
    target_date: Optional[date] = Query(None, alias="date", description="Date (default: latest)"),
    limit: int = Query(10, ge=1, le=500, description="Number of results"),
    index: Optional[str] = Query(
        None, description="Filter by single index: SP500, DOW30, NASDAQ100 (default: all three)"
    ),
    db: Session = Depends(get_db),
):
    """
    시가총액 상위 개별종목 (홈 '시가총액' 섹션용).

    - SP500 / DOW30 / NASDAQ100 구성종목만 대상 → ETF·종합지수 자연 제외
    - analytics.ticker_key_metrics.market_cap 기준 내림차순 정렬
    - 응답 형태는 /scores/top 과 동일(TopTickerResponse) — 앱 재사용
    """
    # 가격/점수 기준일
    if target_date is None:
        target_date = (
            db.query(func.max(TickerPrice.date))
            .filter(TickerPrice.trading_value.isnot(None))
            .scalar()
        )
    if target_date is None:
        return []

    # 시총(펀더멘털) 최신일 — 가격일과 다를 수 있어 별도 산정
    mc_date = (
        db.query(func.max(TickerKeyMetrics.date))
        .filter(TickerKeyMetrics.date <= target_date)
        .scalar()
    )
    if mc_date is None:
        return []

    index_codes = [index] if index else ["SP500", "DOW30", "NASDAQ100"]
    member_subq = (
        db.query(StockMembership.ticker)
        .filter(StockMembership.index_code.in_(index_codes))
        .distinct()
    )

    rows = (
        db.query(
            TickerKeyMetrics.ticker,
            TickerKeyMetrics.market_cap,
            TickerScore.score,
            TickerScore.signal,
            Ticker.name,
            Ticker.extra_data,
            TickerPrice.close,
            TickerPrice.change_pct,
        )
        .outerjoin(Ticker, TickerKeyMetrics.ticker == Ticker.ticker)
        .outerjoin(
            TickerPrice,
            (TickerKeyMetrics.ticker == TickerPrice.ticker)
            & (TickerPrice.date == target_date),
        )
        .outerjoin(
            TickerScore,
            (TickerKeyMetrics.ticker == TickerScore.ticker)
            & (TickerScore.date == target_date),
        )
        .filter(
            TickerKeyMetrics.date == mc_date,
            TickerKeyMetrics.market_cap.isnot(None),
            TickerKeyMetrics.ticker.in_(member_subq),
        )
        .order_by(desc(TickerKeyMetrics.market_cap))
        .limit(limit)
        .all()
    )

    # 방어적 ETF 이름 제외 (구성종목엔 거의 없지만 안전장치)
    rows = [
        r for r in rows
        if not any(kw in (r.name or "").upper() for kw in _ETF_NAME_KEYWORDS)
    ]

    result_tickers = [r.ticker for r in rows]
    membership_rows = (
        db.query(StockMembership.ticker, StockMembership.index_code)
        .filter(StockMembership.ticker.in_(result_tickers))
        .all()
        if result_tickers else []
    )
    membership_map: dict[str, list[str]] = {}
    for m in membership_rows:
        membership_map.setdefault(m.ticker, []).append(m.index_code)

    return [
        {
            "ticker": r.ticker,
            "score": r.score if r.score is not None else 0.0,
            "signal": translate_signal(r.signal),
            "name": r.name,
            "name_ko": r.extra_data.get("name_ko") if r.extra_data else None,
            "membership": membership_map.get(r.ticker),
            "close": r.close,
            "change_pct": r.change_pct,
        }
        for r in rows
    ]

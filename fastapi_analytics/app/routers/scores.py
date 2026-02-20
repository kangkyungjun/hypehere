from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from datetime import date, timedelta
from typing import List, Optional
from app.database import get_db
from app.models import TickerScore, Ticker, StockMembership
from app.schemas import TickerScoreListResponse, TopTickerResponse
from app.utils.trading_calendar import get_latest_trading_date

router = APIRouter()


# Signal translation mapping (Korean → English)
SIGNAL_MAPPING = {
    "🔥강력매수": "BUY",
    "매수권고": "BUY",
    "보유": "HOLD",
    "중립": "HOLD",
    "매도권고": "SELL",
    "🔥강력매도": "SELL",
}


def translate_signal(korean_signal: str | None) -> str | None:
    """
    Translate Korean signals to English codes for API response.

    Internal logic codes (stable):
    - "BUY": Strong buy signal
    - "SELL": Strong sell signal
    - "HOLD": Neutral or hold signal

    Args:
        korean_signal: Korean signal from Mac mini DB (e.g., "🔥강력매수")

    Returns:
        English code: "BUY", "SELL", "HOLD", or None
    """
    if korean_signal is None:
        return None
    return SIGNAL_MAPPING.get(korean_signal, "HOLD")


@router.get("/top", response_model=List[TopTickerResponse])
def get_top_scores(
    target_date: date = Query(None, alias="date", description="Date (default: today)"),
    limit: int = Query(10, le=500, ge=1, description="Number of results (max 500)"),
    index: Optional[str] = Query(None, description="Filter by index: SP500, DOW30, NASDAQ100"),
    db: Session = Depends(get_db)
):
    """
    Get top scoring tickers for a specific date.

    **홈 화면용** ⭐
    - 오늘의 상위 종목
    - 시그널 포함
    - 이름 포함 (ticker metadata join)
    - index 파라미터로 지수별 필터링 가능

    Example:
    ```
    GET /api/v1/scores/top?date=2026-02-02&limit=10&index=SP500
    ```
    """
    if target_date is None:
        # Use latest trading day instead of raw MAX(date) to skip weekends/holidays
        latest_date = get_latest_trading_date(db)
        if latest_date is None:
            # DB 전체가 비어있으면 빈 배열 반환 (404 금지)
            return []
        target_date = latest_date

    # Join with ticker metadata for names
    query = db.query(
        TickerScore.ticker,
        TickerScore.score,
        TickerScore.signal,
        Ticker.name,
        Ticker.extra_data  # JSONB metadata (contains name_ko)
    ).outerjoin(
        Ticker,
        TickerScore.ticker == Ticker.ticker
    ).filter(
        TickerScore.date == target_date
    )

    # Optional index filter
    if index:
        query = query.join(
            StockMembership,
            (TickerScore.ticker == StockMembership.ticker) &
            (StockMembership.index_code == index)
        )

    results = query.order_by(
        desc(TickerScore.score)
    ).limit(limit).all()

    # Batch-fetch memberships for all result tickers
    result_tickers = [r.ticker for r in results]
    memberships_rows = db.query(
        StockMembership.ticker, StockMembership.index_code
    ).filter(StockMembership.ticker.in_(result_tickers)).all() if result_tickers else []

    membership_map: dict[str, list[str]] = {}
    for m in memberships_rows:
        membership_map.setdefault(m.ticker, []).append(m.index_code)

    # 결과 없어도 빈 배열 반환 (404 금지)
    return [
        {
            "ticker": r.ticker,
            "score": r.score,
            "signal": translate_signal(r.signal),  # Korean → English translation
            "name": r.name,
            "name_ko": r.extra_data.get("name_ko") if r.extra_data else None,
            "membership": membership_map.get(r.ticker),
        }
        for r in results
    ]


@router.get("/insights")
def get_market_insights(
    target_date: date = Query(None, alias="date", description="Date (default: today)"),
    top: int = Query(5, ge=1, le=500, description="Number of top movers (max 500)"),
    bottom: int = Query(5, ge=1, le=500, description="Number of bottom movers (max 500)"),
    index: Optional[str] = Query(None, description="Filter by index: SP500, DOW30, NASDAQ100"),
    db: Session = Depends(get_db)
):
    """
    Get market insights with top and bottom performers.

    **대시보드용** ⭐⭐⭐
    - 강세 종목 (점수 높은 순)
    - 약세 종목 (점수 낮은 순)
    - index 파라미터로 지수별 필터링 가능
    """
    if target_date is None:
        # Use latest trading day instead of raw MAX(date) to skip weekends/holidays
        latest_date = get_latest_trading_date(db)
        if latest_date is None:
            # DB 전체가 비어있으면 빈 구조 반환 (404 금지)
            return {"date": None, "top_movers": [], "bottom_movers": []}
        target_date = latest_date

    # Base query builder
    def _build_base_query():
        q = db.query(
            TickerScore.ticker,
            TickerScore.score,
            TickerScore.signal,
            Ticker.name,
            Ticker.extra_data  # JSONB metadata (contains name_ko)
        ).outerjoin(
            Ticker,
            TickerScore.ticker == Ticker.ticker
        ).filter(
            TickerScore.date == target_date
        )
        if index:
            q = q.join(
                StockMembership,
                (TickerScore.ticker == StockMembership.ticker) &
                (StockMembership.index_code == index)
            )
        return q

    # Query top movers (highest scores)
    top_results = _build_base_query().order_by(
        desc(TickerScore.score)
    ).limit(top).all()

    # Query bottom movers (lowest scores)
    bottom_results = _build_base_query().order_by(
        TickerScore.score.asc()
    ).limit(bottom).all()

    # Batch-fetch memberships
    all_tickers = list({r.ticker for r in top_results} | {r.ticker for r in bottom_results})
    memberships_rows = db.query(
        StockMembership.ticker, StockMembership.index_code
    ).filter(StockMembership.ticker.in_(all_tickers)).all() if all_tickers else []

    membership_map: dict[str, list[str]] = {}
    for m in memberships_rows:
        membership_map.setdefault(m.ticker, []).append(m.index_code)

    def _format_result(r):
        return {
            "ticker": r.ticker,
            "score": r.score,
            "signal": translate_signal(r.signal),
            "name": r.name,
            "name_ko": r.extra_data.get("name_ko") if r.extra_data else None,
            "membership": membership_map.get(r.ticker),
        }

    # 결과 없어도 빈 배열 반환 (404 금지)
    return {
        "date": str(target_date),
        "top_movers": [_format_result(r) for r in top_results],
        "bottom_movers": [_format_result(r) for r in bottom_results],
    }


@router.get("/{ticker}", response_model=TickerScoreListResponse)
def get_ticker_scores(
    ticker: str,
    from_date: date = Query(None, alias="from", description="Start date (default: 30 days ago)"),
    to_date: date = Query(None, alias="to", description="End date (default: today)"),
    db: Session = Depends(get_db)
):
    """
    Get score history for a specific ticker.

    **MVP 핵심 엔드포인트** ⭐⭐⭐
    - 종목 검색
    - 기간 필터
    - 점수 변화 그래프

    Example:
    ```
    GET /api/v1/scores/AAPL?from=2026-01-01&to=2026-02-02
    ```

    Response:
    ```json
    {
        "ticker": "AAPL",
        "scores": [
            {"date": "2026-01-01", "score": 85.2, "signal": "BUY"},
            {"date": "2026-01-02", "score": 87.1, "signal": "BUY"}
        ]
    }
    ```
    """
    # Default date range: last 30 days
    if to_date is None:
        to_date = date.today()
    if from_date is None:
        from_date = to_date - timedelta(days=30)

    # Validate date range
    if from_date > to_date:
        raise HTTPException(400, "from_date must be before to_date")

    # Query scores
    scores = db.query(TickerScore).filter(
        TickerScore.ticker == ticker.upper(),
        TickerScore.date >= from_date,
        TickerScore.date <= to_date
    ).order_by(TickerScore.date.asc()).all()

    if not scores:
        raise HTTPException(
            404,
            f"No scores found for ticker '{ticker}' in date range {from_date} to {to_date}"
        )

    return {
        "ticker": ticker.upper(),
        "scores": scores
    }

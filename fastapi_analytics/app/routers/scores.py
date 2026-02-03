from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc
from datetime import date, timedelta
from typing import List
from app.database import get_db
from app.models import TickerScore, Ticker
from app.schemas import TickerScoreListResponse, TopTickerResponse

router = APIRouter()


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


@router.get("/top", response_model=List[TopTickerResponse])
def get_top_scores(
    target_date: date = Query(None, alias="date", description="Date (default: today)"),
    limit: int = Query(10, le=50, ge=1, description="Number of results (max 50)"),
    db: Session = Depends(get_db)
):
    """
    Get top scoring tickers for a specific date.

    **홈 화면용** ⭐
    - 오늘의 상위 종목
    - 시그널 포함
    - 이름 포함 (ticker metadata join)

    Example:
    ```
    GET /api/v1/scores/top?date=2026-02-02&limit=10
    ```

    Response:
    ```json
    [
        {
            "ticker": "AAPL",
            "score": 92.5,
            "signal": "BUY",
            "name": "Apple Inc."
        },
        {
            "ticker": "TSLA",
            "score": 88.3,
            "signal": "HOLD",
            "name": "Tesla, Inc."
        }
    ]
    ```
    """
    if target_date is None:
        target_date = date.today()

    # Join with ticker metadata for names
    results = db.query(
        TickerScore.ticker,
        TickerScore.score,
        TickerScore.signal,
        Ticker.name
    ).outerjoin(
        Ticker,
        TickerScore.ticker == Ticker.ticker
    ).filter(
        TickerScore.date == target_date
    ).order_by(
        desc(TickerScore.score)
    ).limit(limit).all()

    if not results:
        raise HTTPException(
            404,
            f"No scores found for date {target_date}"
        )

    return [
        {
            "ticker": r.ticker,
            "score": r.score,
            "signal": r.signal,
            "name": r.name
        }
        for r in results
    ]

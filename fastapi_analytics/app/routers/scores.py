from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from datetime import date, timedelta
from typing import List
from app.database import get_db
from app.models import TickerScore, Ticker
from app.schemas import TickerScoreListResponse, TopTickerResponse

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
        # Use latest available date instead of today (fallback for missing data)
        latest_date = db.query(func.max(TickerScore.date)).scalar()
        if latest_date is None:
            # DB 전체가 비어있으면 빈 배열 반환 (404 금지)
            return []
        target_date = latest_date

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

    # 결과 없어도 빈 배열 반환 (404 금지)
    return [
        {
            "ticker": r.ticker,
            "score": r.score,
            "signal": translate_signal(r.signal),  # Korean → English translation
            "name": r.name
        }
        for r in results
    ]


@router.get("/insights")
def get_market_insights(
    target_date: date = Query(None, alias="date", description="Date (default: today)"),
    top: int = Query(5, ge=1, le=50, description="Number of top movers (max 50)"),
    bottom: int = Query(5, ge=1, le=50, description="Number of bottom movers (max 50)"),
    db: Session = Depends(get_db)
):
    """
    Get market insights with top and bottom performers.

    **대시보드용** ⭐⭐⭐
    - 강세 종목 (점수 높은 순)
    - 약세 종목 (점수 낮은 순)
    - 매수/매도 후보 파악

    Example:
    ```
    GET /api/v1/scores/insights?date=2026-02-03&top=5&bottom=5
    ```

    Response:
    ```json
    {
        "date": "2026-02-03",
        "top_movers": [
            {
                "ticker": "NVDA",
                "score": 95.2,
                "signal": "BUY",
                "name": "NVIDIA Corporation"
            }
        ],
        "bottom_movers": [
            {
                "ticker": "INTC",
                "score": 32.1,
                "signal": "SELL",
                "name": "Intel Corporation"
            }
        ]
    }
    ```
    """
    if target_date is None:
        # Use latest available date instead of today (fallback for missing data)
        latest_date = db.query(func.max(TickerScore.date)).scalar()
        if latest_date is None:
            # DB 전체가 비어있으면 빈 구조 반환 (404 금지)
            return {"date": None, "top_movers": [], "bottom_movers": []}
        target_date = latest_date

    # Query top movers (highest scores)
    top_results = db.query(
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
    ).limit(top).all()

    # Query bottom movers (lowest scores)
    bottom_results = db.query(
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
        TickerScore.score.asc()
    ).limit(bottom).all()

    # 결과 없어도 빈 배열 반환 (404 금지)
    return {
        "date": str(target_date),
        "top_movers": [
            {
                "ticker": r.ticker,
                "score": r.score,
                "signal": translate_signal(r.signal),  # Korean → English translation
                "name": r.name
            }
            for r in top_results
        ],
        "bottom_movers": [
            {
                "ticker": r.ticker,
                "score": r.score,
                "signal": translate_signal(r.signal),  # Korean → English translation
                "name": r.name
            }
            for r in bottom_results
        ]
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

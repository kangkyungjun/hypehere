from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_, distinct
from typing import List
from app.database import get_db
from app.models import Ticker, TickerScore
from app.schemas import TickerMetadata

router = APIRouter()


@router.get("/search", response_model=List[TickerMetadata])
def search_tickers(
    q: str = Query(..., min_length=1, description="Search query (ticker or name)"),
    limit: int = Query(20, le=50, ge=1, description="Number of results (max 50)"),
    db: Session = Depends(get_db)
):
    """
    Search tickers by symbol or name.

    **검색 기능** ⭐
    - 심볼 또는 이름으로 검색
    - **실제 분석 대상 종목 기준** (TickerScore 테이블)
    - 메타데이터는 Ticker 테이블과 LEFT JOIN

    Example:
    ```
    GET /api/v1/tickers/search?q=apple
    ```

    Response:
    ```json
    [
        {
            "ticker": "AAPL",
            "name": "Apple Inc.",
            "category": "Technology"
        }
    ]
    ```
    """
    # Search from actual analyzed tickers (TickerScore) with metadata (Ticker)
    # LEFT JOIN으로 TickerScore에 있는 모든 ticker를 검색하되
    # Ticker 테이블에 메타데이터가 있으면 함께 반환
    results = db.query(
        TickerScore.ticker,
        Ticker.name,
        Ticker.category,
        Ticker.extra_data  # JSONB metadata (contains name_ko)
    ).outerjoin(
        Ticker,
        TickerScore.ticker == Ticker.ticker
    ).filter(
        or_(
            TickerScore.ticker.ilike(f"%{q}%"),
            Ticker.name.ilike(f"%{q}%")
        )
    ).distinct(
        TickerScore.ticker
    ).limit(limit).all()

    # 검색 결과 0개도 정상 응답 (200 OK + 빈 배열)
    return [
        {
            "ticker": r.ticker,
            "name": r.name,
            "name_ko": r.extra_data.get("name_ko") if r.extra_data else None,
            "category": r.category
        }
        for r in results
    ]


@router.get("/{ticker}", response_model=TickerMetadata)
def get_ticker_info(
    ticker: str,
    db: Session = Depends(get_db)
):
    """
    Get ticker metadata by symbol.

    Example:
    ```
    GET /api/v1/tickers/AAPL
    ```

    Response:
    ```json
    {
        "ticker": "AAPL",
        "name": "Apple Inc.",
        "category": "Technology"
    }
    ```
    """
    result = db.query(Ticker).filter(
        Ticker.ticker == ticker.upper()
    ).first()

    if not result:
        raise HTTPException(
            404,
            f"Ticker not found: {ticker}"
        )

    # Extract name_ko from JSONB metadata and return as dict
    return {
        "ticker": result.ticker,
        "name": result.name,
        "name_ko": result.extra_data.get("name_ko") if result.extra_data else None,
        "category": result.category
    }

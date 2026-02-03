from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List
from app.database import get_db
from app.models import Ticker
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
    - 메타데이터만 반환

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
    # Search by ticker symbol or name
    tickers = db.query(Ticker).filter(
        or_(
            Ticker.ticker.ilike(f"%{q}%"),
            Ticker.ticker_name.ilike(f"%{q}%"),
            Ticker.name.ilike(f"%{q}%")
        )
    ).limit(limit).all()

    if not tickers:
        raise HTTPException(
            404,
            f"No tickers found matching '{q}'"
        )

    return tickers


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

    return result

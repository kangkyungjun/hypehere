from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date, timedelta
from typing import List
from app.database import get_db
from app.models import TickerPrice
from app.schemas import TickerPriceListResponse

router = APIRouter()


@router.get("/{ticker}", response_model=TickerPriceListResponse)
def get_ticker_prices(
    ticker: str,
    from_date: date = Query(None, alias="from", description="Start date (default: 30 days ago)"),
    to_date: date = Query(None, alias="to", description="End date (default: today)"),
    db: Session = Depends(get_db)
):
    """
    Get OHLCV price history for charting.

    **차트용 API** ⭐⭐
    - 웹 대시보드 차트
    - Flutter 앱 차트
    - 기간 필터 (1개월 / 3개월 / 1년)

    Example:
    ```
    GET /api/v1/prices/AAPL?from=2026-01-01&to=2026-02-06
    ```

    Response:
    ```json
    {
        "ticker": "AAPL",
        "prices": [
            {
                "date": "2026-01-15",
                "open": 182.3,
                "high": 185.1,
                "low": 181.9,
                "close": 184.7,
                "volume": 53200000
            }
        ]
    }
    ```
    """
    # Default date range: last 30 days
    if to_date is None:
        # Use latest available date instead of today (fallback for missing data)
        latest_date = db.query(func.max(TickerPrice.date)).scalar()
        if latest_date is None:
            raise HTTPException(404, "No price data available in database")
        to_date = latest_date

    if from_date is None:
        from_date = to_date - timedelta(days=30)

    # Validate date range
    if from_date > to_date:
        raise HTTPException(400, "from_date must be before to_date")

    # Query prices
    prices = db.query(TickerPrice).filter(
        TickerPrice.ticker == ticker.upper(),
        TickerPrice.date >= from_date,
        TickerPrice.date <= to_date
    ).order_by(TickerPrice.date.asc()).all()

    if not prices:
        raise HTTPException(
            404,
            f"No price data found for ticker '{ticker}' in date range {from_date} to {to_date}"
        )

    return {
        "ticker": ticker.upper(),
        "prices": prices
    }

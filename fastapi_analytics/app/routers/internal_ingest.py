from fastapi import APIRouter, Header, HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import date

from app.database import get_db
from app.models import TickerScore, TickerPrice
from app.config import settings

router = APIRouter(
    prefix="/api/v1/internal/ingest",
    tags=["Internal"],
)

EXPECTED_API_KEY = settings.ANALYTICS_API_KEY


# ============================
# API Key 검증
# ============================
def verify_api_key(x_api_key: str = Header(None)):
    """
    Verify API key for internal endpoints.

    Raises:
        HTTPException: 403 if API key is invalid or missing
        HTTPException: 500 if server API key is not configured
    """
    if EXPECTED_API_KEY is None:
        raise HTTPException(
            status_code=500,
            detail="Server API key not configured"
        )

    if x_api_key != EXPECTED_API_KEY:
        raise HTTPException(
            status_code=403,
            detail="Invalid API key"
        )


# ============================
# 점수 Ingest 엔드포인트
# ============================
@router.post("/scores", dependencies=[Depends(verify_api_key)])
def ingest_scores(payload: dict, db: Session = Depends(get_db)):
    """
    Ingest ticker scores from Mac mini.

    **Internal API** - Not for mobile app use.

    Payload format:
    ```json
    {
        "date": "2026-02-03",
        "count": 503,
        "items": [
            {
                "date": "2026-02-03",
                "ticker": "AAPL",
                "score": 85.7,
                "signal": "BUY"
            }
        ]
    }
    ```

    Features:
    - UPSERT logic (ticker + date as unique key)
    - Auto-delete data older than 3 years
    - Safe for duplicate uploads

    Returns:
    ```json
    {
        "status": "ok",
        "received": 503,
        "upserted": 503
    }
    ```
    """
    if "items" not in payload:
        raise HTTPException(status_code=400, detail="Invalid payload: 'items' key required")

    items = payload["items"]
    upserted = 0

    for item in items:
        # Validate required fields
        if not all(k in item for k in ("ticker", "date")):
            continue

        ticker = item["ticker"]
        score_date_str = item["date"]

        # Convert date string to date object
        if isinstance(score_date_str, str):
            from datetime import datetime
            score_date = datetime.strptime(score_date_str, "%Y-%m-%d").date()
        else:
            score_date = score_date_str

        # ==========================================
        # 1) UPSERT to ticker_prices (OHLCV data)
        # ==========================================
        price_obj = (
            db.query(TickerPrice)
            .filter(
                TickerPrice.ticker == ticker,
                TickerPrice.date == score_date,
            )
            .first()
        )

        if price_obj:
            # Update existing price record
            price_obj.open = item.get("open")
            price_obj.high = item.get("high")
            price_obj.low = item.get("low")
            price_obj.close = item.get("close")
            price_obj.volume = item.get("volume")
        else:
            # Insert new price record
            price_obj = TickerPrice(
                ticker=ticker,
                date=score_date,
                open=item.get("open"),
                high=item.get("high"),
                low=item.get("low"),
                close=item.get("close"),
                volume=item.get("volume"),
            )
            db.add(price_obj)

        # ==========================================
        # 2) UPSERT to ticker_scores (score data)
        # ==========================================
        score_value = item.get("score")
        signal = item.get("signal")

        # Only process score if provided
        if score_value is not None:
            score_obj = (
                db.query(TickerScore)
                .filter(
                    TickerScore.ticker == ticker,
                    TickerScore.date == score_date,
                )
                .first()
            )

            if score_obj:
                # Update existing score record
                score_obj.score = score_value
                score_obj.signal = signal
            else:
                # Insert new score record
                score_obj = TickerScore(
                    ticker=ticker,
                    date=score_date,
                    score=score_value,
                    signal=signal,
                )
                db.add(score_obj)

        upserted += 1

    db.commit()

    # ----------------------------
    # 3년 초과 데이터 자동 삭제
    # ----------------------------
    db.execute(
        text("""
        DELETE FROM analytics.ticker_scores
        WHERE date < CURRENT_DATE - INTERVAL '3 years'
        """)
    )
    db.commit()

    return {
        "status": "ok",
        "received": len(items),
        "upserted": upserted,
    }

from fastapi import APIRouter, Header, HTTPException, Depends
from sqlalchemy.orm import Session
from datetime import date

from app.database import get_db
from app.models import TickerScore
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
        if not all(k in item for k in ("ticker", "date", "score")):
            continue

        ticker = item["ticker"]
        score_date_str = item["date"]
        score_value = item["score"]
        signal = item.get("signal")

        # Convert date string to date object
        if isinstance(score_date_str, str):
            from datetime import datetime
            score_date = datetime.strptime(score_date_str, "%Y-%m-%d").date()
        else:
            score_date = score_date_str

        # UPSERT 로직: ticker + date 기준
        obj = (
            db.query(TickerScore)
            .filter(
                TickerScore.ticker == ticker,
                TickerScore.date == score_date,
            )
            .first()
        )

        if obj:
            # Update existing record
            obj.score = score_value
            obj.signal = signal
        else:
            # Insert new record
            obj = TickerScore(
                ticker=ticker,
                date=score_date,
                score=score_value,
                signal=signal,
            )
            db.add(obj)

        upserted += 1

    db.commit()

    # ----------------------------
    # 3년 초과 데이터 자동 삭제
    # ----------------------------
    db.execute(
        """
        DELETE FROM analytics.ticker_scores
        WHERE date < CURRENT_DATE - INTERVAL '3 years'
        """
    )
    db.commit()

    return {
        "status": "ok",
        "received": len(items),
        "upserted": upserted,
    }

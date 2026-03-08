from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from collections import defaultdict
import logging

from app.database import get_db
from app.models import MarketCalendarEvent, EarningsWeekEvent
from app.schemas import MarketCalendarEventResponse, MarketCalendarResponse

logger = logging.getLogger(__name__)

router = APIRouter()

# 다국어 언패킹 순서: ko=0, en=1, zh=2, ja=3, es=4
LANG_ORDER = ["ko", "en", "zh", "ja", "es"]


def unpack_multilang(packed: str, lang: str) -> str:
    """'ko|||en|||zh|||ja|||es' → 해당 언어 문자열, 없으면 en fallback"""
    parts = packed.split("|||")
    idx = LANG_ORDER.index(lang) if lang in LANG_ORDER else 1  # default en
    if idx < len(parts) and parts[idx].strip():
        return parts[idx].strip()
    return parts[1].strip() if len(parts) > 1 else parts[0].strip()  # en fallback


IMPORTANCE_ORDER = {"high": 0, "medium": 1, "low": 2}


@router.get("/calendar", response_model=MarketCalendarResponse)
def get_event_calendar(
    year: int = Query(..., ge=2020, le=2040),
    month: int = Query(..., ge=1, le=12),
    lang: str = Query("en", max_length=5),
    db: Session = Depends(get_db),
):
    """
    월별 이벤트 캘린더 조회.

    market_calendar + earnings_week_events 합산하여 by_date 그룹핑 반환.
    title/description는 lang 파라미터로 언패킹.
    """
    # 1) market_calendar에서 해당 월 이벤트 쿼리
    from sqlalchemy import extract
    events = (
        db.query(MarketCalendarEvent)
        .filter(
            extract("year", MarketCalendarEvent.event_date) == year,
            extract("month", MarketCalendarEvent.event_date) == month,
        )
        .all()
    )

    by_date = defaultdict(list)

    for ev in events:
        date_str = ev.event_date.strftime("%Y-%m-%d")
        by_date[date_str].append(MarketCalendarEventResponse(
            id=ev.id,
            date=date_str,
            event_type=ev.event_type,
            title=unpack_multilang(ev.title, lang),
            description=unpack_multilang(ev.description, lang) if ev.description else None,
            ticker=ev.ticker,
            importance=ev.importance or "medium",
        ))

    # 2) earnings_week_events에서 해당 월 실적도 합산
    earnings = (
        db.query(EarningsWeekEvent)
        .filter(
            extract("year", EarningsWeekEvent.earnings_date) == year,
            extract("month", EarningsWeekEvent.earnings_date) == month,
        )
        .all()
    )

    for earn in earnings:
        date_str = earn.earnings_date.strftime("%Y-%m-%d")
        # 언어별 이름
        if lang == "ko" and earn.name_ko:
            title = f"{earn.name_ko} ({earn.ticker})"
        else:
            title = f"{earn.name_en or earn.ticker} ({earn.ticker})"

        by_date[date_str].append(MarketCalendarEventResponse(
            id=f"earn_{earn.ticker}_{date_str}",
            date=date_str,
            event_type="earnings",
            title=title,
            description=None,
            ticker=earn.ticker,
            importance="high" if (earn.score and earn.score >= 70) else "medium",
        ))

    # 3) importance DESC 정렬
    for date_str in by_date:
        by_date[date_str].sort(key=lambda e: IMPORTANCE_ORDER.get(e.importance, 1))

    total = sum(len(v) for v in by_date.values())

    return MarketCalendarResponse(
        year=year,
        month=month,
        total_count=total,
        by_date=dict(by_date),
    )

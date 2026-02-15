from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from datetime import date, timedelta
from collections import defaultdict

from app.database import get_db
from app.models import EarningsWeekEvent
from app.schemas import EarningsUpcomingResponse, EarningsWeekEventResponse

router = APIRouter()


@router.get("/upcoming", response_model=EarningsUpcomingResponse)
def get_upcoming_earnings(
    days: int = Query(7, ge=1, le=30, description="Number of days ahead (default 7)"),
    db: Session = Depends(get_db),
):
    """
    이번 주 실적 발표 일정 조회.

    날짜별 그룹핑하여 반환. Flutter 앱 캘린더 화면용.
    """
    today = date.today()
    end_date = today + timedelta(days=days)

    events = db.query(EarningsWeekEvent).filter(
        EarningsWeekEvent.earnings_date >= today,
        EarningsWeekEvent.earnings_date <= end_date,
    ).order_by(
        EarningsWeekEvent.earnings_date.asc(),
        EarningsWeekEvent.market_cap.desc(),
    ).all()

    # Group by date
    by_date = defaultdict(list)
    for ev in events:
        date_str = str(ev.earnings_date)
        by_date[date_str].append(EarningsWeekEventResponse(
            ticker=ev.ticker,
            earnings_date=date_str,
            earnings_time=ev.earnings_time,
            eps_estimate=ev.eps_estimate,
            revenue_estimate=ev.revenue_estimate,
            market_cap=ev.market_cap,
            sector=ev.sector,
            name_en=ev.name_en,
            name_ko=ev.name_ko,
        ))

    return EarningsUpcomingResponse(
        week_start=str(today),
        week_end=str(end_date),
        total_count=len(events),
        by_date=dict(by_date),
    )

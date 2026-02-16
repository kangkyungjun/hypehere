from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date, timedelta
from collections import defaultdict

from app.database import get_db
from app.models import EarningsWeekEvent, TickerCalendar, Ticker
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
    EarningsWeekEvent 우선 조회, 비어 있으면 TickerCalendar fallback.
    """
    today = date.today()
    end_date = today + timedelta(days=days)

    # Primary: EarningsWeekEvent (Mac mini가 주 단위로 전송)
    events = db.query(EarningsWeekEvent).filter(
        EarningsWeekEvent.earnings_date >= today,
        EarningsWeekEvent.earnings_date <= end_date,
    ).order_by(
        EarningsWeekEvent.earnings_date.asc(),
        EarningsWeekEvent.market_cap.desc(),
    ).all()

    if events:
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

    # Fallback: TickerCalendar (scores ingest에서 자동 수집된 데이터)
    # 최신 date 기준으로 ticker별 최신 next_earnings_date 조회
    latest_date_sub = db.query(
        TickerCalendar.ticker,
        func.max(TickerCalendar.date).label("max_date"),
    ).group_by(TickerCalendar.ticker).subquery()

    rows = db.query(TickerCalendar, Ticker).join(
        latest_date_sub,
        (TickerCalendar.ticker == latest_date_sub.c.ticker) &
        (TickerCalendar.date == latest_date_sub.c.max_date),
    ).outerjoin(
        Ticker, TickerCalendar.ticker == Ticker.ticker,
    ).filter(
        TickerCalendar.next_earnings_date >= today,
        TickerCalendar.next_earnings_date <= end_date,
    ).order_by(
        TickerCalendar.next_earnings_date.asc(),
    ).all()

    by_date = defaultdict(list)
    for cal, tkr in rows:
        date_str = str(cal.next_earnings_date)
        name_ko = None
        if tkr and tkr.extra_data and isinstance(tkr.extra_data, dict):
            name_ko = tkr.extra_data.get("name_ko")

        by_date[date_str].append(EarningsWeekEventResponse(
            ticker=cal.ticker,
            earnings_date=date_str,
            earnings_time=None,
            eps_estimate=cal.earnings_avg,
            revenue_estimate=cal.revenue_avg,
            market_cap=None,
            sector=tkr.sector if tkr else None,
            name_en=tkr.name if tkr else None,
            name_ko=name_ko,
        ))

    total = sum(len(v) for v in by_date.values())
    return EarningsUpcomingResponse(
        week_start=str(today),
        week_end=str(end_date),
        total_count=total,
        by_date=dict(by_date),
    )

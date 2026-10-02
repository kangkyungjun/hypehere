"""
Internal users router (Mac mini 풀 동기화).

맥미니가 유저별 holdings + watchlist 전량을 끌어가 개인화 분석/의견 생성에 사용.
데이터 소스: analytics.user_portfolios (type = HOLDING | WATCHLIST) — 단일 소스.

주의: user_portfolios 에는 target_buy_price / added_date(별도) / ai_alert_enabled 컬럼이
없으므로 available 필드로 매핑하고 나머지는 null. (created_at ≈ added/buy date,
avg_price ≈ buy_price, shares ≈ quantity)
"""
from datetime import datetime, timezone, timedelta

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import text, bindparam

from app.database import get_db
from app.routers.internal_ingest import verify_api_key
from app.schemas import (
    InternalPortfoliosOut, InternalHoldingOut, InternalWatchlistOut,
)

router = APIRouter(
    prefix="/api/v1/internal/users",
    tags=["Internal"],
)

# 접속 지표 월경계 TZ — activity.py 핑/롤업과 동일하게 KST 고정.
_ACTIVITY_TZ = timezone(timedelta(hours=9))


class ActivityMetricsIn(BaseModel):
    user_ids: list[int]


class UserActivityMetric(BaseModel):
    user_id: int
    last_access: str | None = None
    total_accesses: int = 0
    total_active_days: int = 0
    month_accesses: int = 0
    month_active_days: int = 0


class ActivityMetricsOut(BaseModel):
    metrics: list[UserActivityMetric]


@router.get(
    "/portfolios",
    response_model=InternalPortfoliosOut,
    dependencies=[Depends(verify_api_key)],
)
def get_all_portfolios(db: Session = Depends(get_db)):
    """
    전체 유저 holdings + watchlist. X-API-Key 인증.
    맥미니 로컬 저장소(local_watchlist / holdings) 풀 동기화용.
    """
    rows = db.execute(text(
        "SELECT user_id, ticker, type, shares, avg_price, created_at "
        "FROM analytics.user_portfolios "
        "ORDER BY user_id, ticker"
    )).fetchall()

    holdings = []
    watchlist = []
    for r in rows:
        d = r.created_at.date().isoformat() if r.created_at else None
        if r.type == 'HOLDING':
            holdings.append(InternalHoldingOut(
                user_id=str(r.user_id),
                ticker=r.ticker,
                buy_price=r.avg_price,
                buy_date=d,
                quantity=r.shares,
                status='HOLDING',
            ))
        else:
            watchlist.append(InternalWatchlistOut(
                user_id=str(r.user_id),
                ticker=r.ticker,
                added_date=d,
                target_buy_price=None,
                ai_alert_enabled=None,
            ))

    return InternalPortfoliosOut(holdings=holdings, watchlist=watchlist)


@router.post(
    "/activity-metrics",
    response_model=ActivityMetricsOut,
    dependencies=[Depends(verify_api_key)],
)
def get_activity_metrics(payload: ActivityMetricsIn, db: Session = Depends(get_db)):
    """유저별 접속 지표 배치 조회 (Django 관리자 패널 프록시용). X-API-Key 인증.

    - 총계/마지막접속: analytics.user_activity_totals (90일 purge 무관 영구 누적).
    - 이번달: analytics.user_activity_daily (raw, 이번 달은 항상 90일 내).
    월경계는 KST 고정(핑/롤업과 동일). analytics 는 이 서버가 소유한 Postgres.
    """
    ids = list(dict.fromkeys(payload.user_ids))  # 중복 제거, 순서 보존
    if not ids:
        return ActivityMetricsOut(metrics=[])

    month_start = datetime.now(_ACTIVITY_TZ).date().replace(day=1)
    metrics: dict[int, dict] = {}

    totals_stmt = text(
        "SELECT user_id, total_accesses, total_active_days, last_access "
        "FROM analytics.user_activity_totals WHERE user_id IN :ids"
    ).bindparams(bindparam("ids", expanding=True))
    for row in db.execute(totals_stmt, {"ids": ids}).fetchall():
        metrics[row.user_id] = {
            "last_access": row.last_access.isoformat() if row.last_access else None,
            "total_accesses": int(row.total_accesses or 0),
            "total_active_days": int(row.total_active_days or 0),
            "month_accesses": 0,
            "month_active_days": 0,
        }

    month_stmt = text(
        "SELECT user_id, COALESCE(SUM(accesses), 0) AS acc, COUNT(*) AS days "
        "FROM analytics.user_activity_daily "
        "WHERE user_id IN :ids AND date >= :month_start GROUP BY user_id"
    ).bindparams(bindparam("ids", expanding=True))
    for row in db.execute(month_stmt, {"ids": ids, "month_start": month_start}).fetchall():
        m = metrics.setdefault(row.user_id, {
            "last_access": None,
            "total_accesses": 0,
            "total_active_days": 0,
            "month_accesses": 0,
            "month_active_days": 0,
        })
        m["month_accesses"] = int(row.acc or 0)
        m["month_active_days"] = int(row.days or 0)

    return ActivityMetricsOut(
        metrics=[UserActivityMetric(user_id=uid, **vals) for uid, vals in metrics.items()]
    )

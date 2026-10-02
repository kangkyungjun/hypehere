"""
유저 활동 핑 (DAU/WAU 수집).

앱이 포그라운드 진입 시 1회 호출. 인증 유저만 기록(익명/헬스체크/봇은 user_id 없어 자동 제외).
하루 1유저 1행(first-touch 플랫폼) — ON CONFLICT DO NOTHING 멱등.

설계 메모(리뷰 반영):
- 미들웨어 대신 전용 인증 핸들러 → get_current_user 정상 사용(미들웨어 인증접근 문제 없음),
  요청 세션으로 동기 INSERT(fire-and-forget 세션 만료 문제 없음).
- 워커 내 seen-set 가드로 그날 첫 핑만 DB INSERT 시도(클라 throttle 우회/버그 시 핑 폭주 방어).
  멀티워커면 워커당 1회씩 샐 수 있으나 ON CONFLICT DO NOTHING 이 정합성 보장(캐시는 최적화일 뿐).
- 활동 기록은 절대 사용자 요청을 막지 않음(예외는 조용히 무시, 항상 204).
"""
import logging
from datetime import datetime, timezone, timedelta

from fastapi import APIRouter, Depends, Header
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db
from app.auth import get_current_user

logger = logging.getLogger(__name__)
router = APIRouter()

# 대시보드 일자 경계 통일 TZ. KST(UTC+9)로 고정 — 롤업 크론·admob/install 수집기도 동일 경계.
_DASHBOARD_TZ = timezone(timedelta(hours=9))

# 세션 카운팅용 플러드 방어 스로틀:
# 예전엔 "하루 1회"만 DB에 기록했으나, 이제 세션(접속) 횟수를 세기 위해 핑마다 카운트한다.
# 다만 짧은 간격의 중복 핑(재포그라운드 연타/버그)이 카운트를 부풀리지 않도록,
# 워커 내에서 유저별 최근 카운트 시각을 두고 _MIN_PING_INTERVAL 미만이면 DB를 건너뛴다.
_MIN_PING_INTERVAL = timedelta(seconds=60)
_guard_date: str | None = None
_last_counted: dict[int, datetime] = {}


def _today_str() -> str:
    return datetime.now(_DASHBOARD_TZ).strftime("%Y-%m-%d")


def _roll(today: str) -> None:
    global _guard_date, _last_counted
    if _guard_date != today:
        _guard_date = today
        _last_counted = {}


def _too_soon(today: str, user_id: int, now: datetime) -> bool:
    _roll(today)
    last = _last_counted.get(user_id)
    return last is not None and (now - last) < _MIN_PING_INTERVAL


def _mark_counted(today: str, user_id: int, now: datetime) -> None:
    _roll(today)
    _last_counted[user_id] = now


@router.post("/ping", status_code=204)
def activity_ping(
    user_id: int = Depends(get_current_user),
    x_platform: str | None = Header(default=None, alias="X-Platform"),
    db: Session = Depends(get_db),
):
    """포그라운드 핑: 세션(접속) 1회로 카운트. 항상 204(no content).

    - user_activity_daily: 하루 1행 유지 + 그 날 세션 횟수(accesses) 증가.
    - user_activity_totals: 영구 누적(총 세션/총 활동일/마지막 접속). 90일 purge 무관.
    - 짧은 간격(_MIN_PING_INTERVAL) 중복 핑은 카운트 생략(플러드 방어).
    """
    now = datetime.now(_DASHBOARD_TZ)
    today = now.strftime("%Y-%m-%d")

    if _too_soon(today, user_id, now):
        return

    platform = x_platform if x_platform in ("ios", "android") else None
    try:
        # 오늘 행 upsert + 세션 카운트 증가. RETURNING (xmax = 0) 으로 "오늘 첫 세션(신규 행)"
        # 여부를 판별 → totals 의 활동일 수를 그 경우에만 +1.
        row = db.execute(
            text(
                "INSERT INTO analytics.user_activity_daily (date, user_id, platform, accesses) "
                "VALUES (:d, :uid, :p, 1) "
                "ON CONFLICT (date, user_id) DO UPDATE "
                "SET accesses = analytics.user_activity_daily.accesses + 1 "
                "RETURNING (xmax = 0) AS is_new_day"
            ),
            {"d": today, "uid": user_id, "p": platform},
        ).first()
        is_new_day = 1 if (row and row[0]) else 0

        db.execute(
            text(
                "INSERT INTO analytics.user_activity_totals "
                "(user_id, total_accesses, total_active_days, last_access) "
                "VALUES (:uid, 1, :nd, :d) "
                "ON CONFLICT (user_id) DO UPDATE SET "
                "total_accesses    = analytics.user_activity_totals.total_accesses + 1, "
                "total_active_days = analytics.user_activity_totals.total_active_days + :nd, "
                "last_access       = GREATEST(analytics.user_activity_totals.last_access, :d), "
                "updated_at        = now()"
            ),
            {"uid": user_id, "nd": is_new_day, "d": today},
        )
        db.commit()
        # 쓰기 성공 후에만 스로틀 표시(실패 시 다음 핑에서 재시도 가능하게).
        _mark_counted(today, user_id, now)
    except Exception:
        db.rollback()
        logger.exception("activity ping insert failed (user_id=%s)", user_id)

    return

"""
거시 지표 AI 변동성 설명 (Macro Explain) — Flutter ↔ Server ↔ 맥미니.

흐름:
  1) POST /api/v1/macro/{indicator_code}/explain  — 인증 사용자 호출.
     - 캐시(`analytics.macro_explanations`, (indicator_code, lang, hour_bucket)) hit이면 즉시 200 + content.
     - miss이면 `analysis_requests` 큐에 request_type='MACRO_EXPLANATION' 적재 후 202 + request_id.
     - body.force=True 면 캐시 무시하고 무조건 enqueue (앱 🔄 버튼, 채팅 쿼터 차감은 앱 책임).
  2) 맥미니가 MACRO_EXPLANATION 큐 폴링 → 답변 생성 →
     POST /api/v1/internal/ingest/macro-explanation 으로 결과 업로드.
  3) GET /api/v1/macro/explain-status/{request_id} — 앱이 백오프 폴링해서 결과 도착 감지.

인증: Django Token (get_current_user). 캐시는 인증 무관(같은 지표는 모든 사용자 공통).
"""
import logging
from datetime import datetime, timezone, timedelta
from typing import Optional

try:
    from zoneinfo import ZoneInfo  # py3.9+
    _ET = ZoneInfo("America/New_York")
except Exception:  # pragma: no cover — 폴백 EST 고정 (DST 무시)
    _ET = timezone(timedelta(hours=-5))

from fastapi import APIRouter, Depends, HTTPException, Path
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db
from app.auth import get_current_user
from app.models import AnalysisRequest
from app.schemas import MacroExplainRequest, MacroExplainOut

logger = logging.getLogger(__name__)
router = APIRouter()

# 우선 VIX 한정 (FRED 시리즈명 'VIXCLS', alias 'VIX'도 허용). 향후 확장 시 여기에 추가.
_ALLOWED_INDICATORS = {"VIX", "VIXCLS"}


def _day_bucket_et(now: Optional[datetime] = None) -> datetime:
    """미국 동부시간(ET) 자정 기준의 일 버킷 — UTC naive datetime으로 반환(DB hour_bucket 컬럼 호환).
    VIX는 미국 시장 지수이므로 ET 거래일 단위로 캐싱한다(같은 ET 일자 = 같은 답변)."""
    n = now or datetime.now(timezone.utc)
    if n.tzinfo is None:
        n = n.replace(tzinfo=timezone.utc)
    et = n.astimezone(_ET)
    et_midnight = et.replace(hour=0, minute=0, second=0, microsecond=0)
    return et_midnight.astimezone(timezone.utc).replace(tzinfo=None)


def _cache_lookup(db: Session, indicator_code: str, lang: str) -> Optional[dict]:
    """현재 시간 버킷에 캐시 있으면 반환, 없으면 None."""
    bucket = _day_bucket_et()
    row = db.execute(
        text(
            "SELECT content, is_error, request_id, updated_at "
            "FROM analytics.macro_explanations "
            "WHERE indicator_code = :ic AND lang = :lg AND hour_bucket = :hb"
        ),
        {"ic": indicator_code, "lg": lang, "hb": bucket},
    ).mappings().fetchone()
    if not row:
        return None
    return {
        "content": row["content"],
        "is_error": bool(row["is_error"]),
        "request_id": row["request_id"],
        "updated_at": row["updated_at"].isoformat() if row["updated_at"] else None,
    }


@router.post("/{indicator_code}/explain", response_model=MacroExplainOut)
def request_macro_explain(
    body: MacroExplainRequest,
    indicator_code: str = Path(..., max_length=32),
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """캐시 hit 시 즉시 done 반환, miss 시 큐 적재 후 pending(+request_id) 반환."""
    code = indicator_code.upper()
    if code not in _ALLOWED_INDICATORS:
        raise HTTPException(
            status_code=400, detail=f"Unsupported indicator: {code}"
        )
    lang = (body.lang or "en").lower()
    if lang not in ("ko", "en"):
        lang = "en"

    # 1) 캐시 확인 (force=True면 스킵)
    if not body.force:
        cached = _cache_lookup(db, code, lang)
        if cached and not cached["is_error"]:
            return MacroExplainOut(
                status="done",
                indicator_code=code,
                lang=lang,
                content=cached["content"],
                is_error=False,
                request_id=cached["request_id"],
                cached=True,
                updated_at=cached["updated_at"],
            )

    # 2) 큐 적재 — request_type='MACRO_EXPLANATION', trigger_data에 코드/lang/recent_values
    trigger = {
        "indicator_code": code,
        "lang": lang,
        "recent_values": [
            {"date": v.date, "value": v.value} for v in (body.recent_values or [])
        ],
    }
    req = AnalysisRequest(
        user_id=user_id,
        request_type="MACRO_EXPLANATION",
        trigger_data=trigger,
    )
    db.add(req)
    db.commit()
    logger.info(
        "Macro explain enqueued: indicator=%s lang=%s user=%s req=%s force=%s",
        code, lang, user_id, req.id, body.force,
    )
    return MacroExplainOut(
        status="pending",
        indicator_code=code,
        lang=lang,
        request_id=req.id,
    )


@router.get("/explain-status/{request_id}", response_model=MacroExplainOut)
def get_macro_explain_status(
    request_id: int,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """앱이 백오프 폴링. 큐 row 상태 + 캐시 join.
    pending / processing → status='pending'. completed → 캐시에서 content 조회."""
    row = db.execute(
        text(
            "SELECT user_id, request_type, status, trigger_data "
            "FROM analytics.analysis_requests WHERE id = :rid"
        ),
        {"rid": request_id},
    ).mappings().fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Request not found")
    if row["user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Not your request")
    if row["request_type"] != "MACRO_EXPLANATION":
        raise HTTPException(status_code=400, detail="Wrong request type")

    td = row["trigger_data"] or {}
    code = (td.get("indicator_code") or "").upper()
    lang = (td.get("lang") or "en").lower()
    if not code:
        raise HTTPException(status_code=500, detail="Corrupt trigger_data")

    if row["status"] in ("PENDING", "PROCESSING"):
        return MacroExplainOut(
            status="pending",
            indicator_code=code,
            lang=lang,
            request_id=request_id,
        )

    # COMPLETED / FAILED → 캐시(이번 시간 버킷) 또는 최신 캐시 lookup
    cached = _cache_lookup(db, code, lang)
    if cached:
        return MacroExplainOut(
            status="done" if not cached["is_error"] else "error",
            indicator_code=code,
            lang=lang,
            content=cached["content"],
            is_error=cached["is_error"],
            request_id=cached["request_id"],
            cached=True,
            updated_at=cached["updated_at"],
        )
    # 캐시가 없는데 큐는 끝났음 — 맥미니 ingest 누락으로 간주.
    return MacroExplainOut(
        status="error",
        indicator_code=code,
        lang=lang,
        is_error=True,
        request_id=request_id,
        content=None,
    )

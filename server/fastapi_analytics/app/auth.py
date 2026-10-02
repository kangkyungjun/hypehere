"""
Django Token cross-schema verification for FastAPI.

Reads public.authtoken_token table to verify Django REST Framework tokens.
Same cross-schema pattern used by FCM service (public.accounts_devicetoken).
"""
from fastapi import Depends, Header, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
import logging

from app.database import get_db

logger = logging.getLogger(__name__)


def get_current_user(
    authorization: str = Header(..., description="Django Token: 'Token <value>'"),
    db: Session = Depends(get_db),
) -> int:
    """
    Verify Django Token and return user_id (integer).

    Reads public.authtoken_token table cross-schema.
    Same pattern as FCM service reading public.accounts_devicetoken.

    Usage:
        @router.get("/my-data")
        def my_endpoint(user_id: int = Depends(get_current_user)):
            ...

    Raises:
        HTTPException 401: Missing or invalid token
    """
    if not authorization or not authorization.startswith("Token "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")

    token_key = authorization[6:]  # Strip "Token " prefix

    result = db.execute(
        text("SELECT user_id FROM public.authtoken_token WHERE key = :token"),
        {"token": token_key},
    ).fetchone()

    if not result:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    return result[0]


def get_optional_user(
    authorization: str = Header(None, description="Optional Django Token"),
    db: Session = Depends(get_db),
) -> int | None:
    """
    Optional auth — returns user_id if token present and valid, None otherwise.

    Usage:
        @router.get("/public-data")
        def endpoint(user_id: int | None = Depends(get_optional_user)):
            if user_id:
                # personalized response
            else:
                # anonymous response
    """
    if not authorization or not authorization.startswith("Token "):
        return None

    token_key = authorization[6:]

    result = db.execute(
        text("SELECT user_id FROM public.authtoken_token WHERE key = :token"),
        {"token": token_key},
    ).fetchone()

    return result[0] if result else None


# ============================================================
# Master 전용 게이트 (어드민 DAU/WAU 대시보드)
#
# ⚠️ 보안 핵심: fail-closed — 역할 조회 실패/비마스터/토큰무효는 전부 거부.
#    클라(앱)의 메뉴 숨김은 우회 가능하므로 이 서버 게이트가 최종 권위.
#
# 역할 출처: Django 'accounts' 앱 커스텀 유저 테이블의 role 컬럼.
#   (FCM 서비스가 public.accounts_devicetoken 을 cross-schema로 읽는 것과 동일 앱.)
#   배포 전 prod 스키마로 아래 3개 상수만 검증/확정할 것:
# ============================================================
_ACCOUNTS_USER_TABLE = "public.accounts_user"   # Django 커스텀 유저 테이블
_ROLE_COLUMN = "role"                            # 역할: master|manager|gold|regular
_MASTER_ROLE = "master"


def get_master_user(
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> int:
    """
    Master 역할만 통과. 그 외(매니저 포함)·조회실패는 403 (fail-closed).

    Usage:
        @router.get("/dashboard/summary")
        def endpoint(user_id: int = Depends(get_master_user)):
            ...
    """
    try:
        row = db.execute(
            text(
                f"SELECT {_ROLE_COLUMN} FROM {_ACCOUNTS_USER_TABLE} "
                "WHERE id = :uid"
            ),
            {"uid": user_id},
        ).fetchone()
    except Exception:
        logger.exception("master role lookup failed (user_id=%s)", user_id)
        # 역할을 못 읽으면 권한 없음으로 간주 — 보안 기본값(절대 통과 X).
        raise HTTPException(status_code=403, detail="Forbidden")

    role = (row[0] if row else None) or ""
    if role.lower() != _MASTER_ROLE:
        raise HTTPException(status_code=403, detail="Master access required")

    return user_id

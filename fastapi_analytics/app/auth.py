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

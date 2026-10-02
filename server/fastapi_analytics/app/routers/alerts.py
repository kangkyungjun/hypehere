"""
User alerts router (Flutter ↔ Server).

Requires Django Token authentication.
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List
import logging

from app.database import get_db
from app.auth import get_current_user
from app.models import UserAlert
from app.schemas import AlertResponse

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("", response_model=List[AlertResponse])
def get_alerts(
    unread_only: bool = Query(False, description="읽지 않은 알림만"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """내 알림 목록 (최신순)"""
    q = db.query(UserAlert).filter(UserAlert.user_id == user_id)
    if unread_only:
        q = q.filter(UserAlert.is_read == False)
    q = q.order_by(UserAlert.created_at.desc())
    return q.offset(offset).limit(limit).all()


@router.post("/{alert_id}/read")
def mark_alert_read(
    alert_id: int,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """알림 읽음 처리"""
    updated = db.query(UserAlert).filter(
        UserAlert.id == alert_id,
        UserAlert.user_id == user_id,
    ).update({"is_read": True})
    db.commit()
    return {"updated": updated}


@router.post("/read-all")
def mark_all_read(
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """모든 알림 읽음 처리"""
    updated = db.query(UserAlert).filter(
        UserAlert.user_id == user_id,
        UserAlert.is_read == False,
    ).update({"is_read": True})
    db.commit()
    return {"updated": updated}

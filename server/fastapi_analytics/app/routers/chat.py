"""
AI 멀티턴 채팅 라우터 (Flutter ↔ Server).

앱 공개 API. 흐름:
  1) POST /messages  — user 턴을 대화 저장소(SoT=서버)에 저장 + analysis_requests 큐에
     request_type='CHAT'로 적재(최근 history 동봉=C 하이브리드) → 202.
  2) 맥미니가 CHAT 큐 폴링 → 처리 → /internal/ingest/chat-message 로 assistant 턴 저장 +
     /analysis-queue/{id}/complete 마킹.
  3) 앱은 GET /conversations/{id}/messages 를 백오프 폴링해 assistant 응답 도착을 감지.

인증: Django Token (get_current_user). conversation_id 는 앱이 생성, 서버가 정본 저장.
"""
import logging
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.auth import get_current_user
from app.models import Conversation, ChatMessage, AnalysisRequest
from app.schemas import ChatSendRequest

logger = logging.getLogger(__name__)

router = APIRouter()

# 큐에 동봉할 최근 대화 턴 수 (C 하이브리드)
_HISTORY_TURNS = 8


@router.post("/messages", status_code=202)
def send_chat_message(
    body: ChatSendRequest,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """사용자 메시지 저장(정본) + CHAT 큐 적재. 202(맥미니 응답 대기 안 함)."""
    conv_id = body.conversation_id

    # 대화 스레드 upsert — 앱 생성 id를 정본 저장
    conv = db.query(Conversation).filter(Conversation.id == conv_id).first()
    if conv is None:
        conv = Conversation(id=conv_id, user_id=user_id, title=body.message[:60])
        db.add(conv)
    elif conv.user_id != user_id:
        raise HTTPException(status_code=403, detail="Not your conversation")
    conv.updated_at = datetime.utcnow()

    # 다음 turn_index = 현재 메시지 수
    next_turn = (
        db.query(func.count(ChatMessage.id))
        .filter(ChatMessage.conversation_id == conv_id)
        .scalar()
    ) or 0

    # user 턴 저장
    db.add(ChatMessage(
        conversation_id=conv_id,
        user_id=user_id,
        role="user",
        content=body.message,
        turn_index=next_turn,
    ))

    # 최근 history 동봉 (맥미니 권장 — 서버 정본 + 큐 적재 시 history)
    recent = (
        db.query(ChatMessage)
        .filter(ChatMessage.conversation_id == conv_id)
        .order_by(ChatMessage.turn_index.desc())
        .limit(_HISTORY_TURNS)
        .all()
    )
    history = [{"role": m.role, "content": m.content} for m in reversed(recent)]
    history.append({"role": "user", "content": body.message})

    # CHAT 큐 적재 (포트폴리오와 동일 테이블, request_type만 다름)
    trigger = {
        "conversation_id": conv_id,
        "message": body.message,
        "lang": body.lang,
        "history": history,
    }
    if body.category:
        # 추천 칩에서 보낸 경우만 동봉 — 맥미니가 카테고리별 컨텍스트 주입 분기.
        # (market_today / portfolio / ticker / sector / macro / education / strategy …)
        trigger["category"] = body.category
    req = AnalysisRequest(
        user_id=user_id,
        request_type="CHAT",
        trigger_data=trigger,
    )
    db.add(req)
    db.commit()

    logger.info(f"Chat enqueued: conv={conv_id}, user={user_id}, req={req.id}")
    return {"status": "queued", "conversation_id": conv_id, "request_id": req.id}


@router.get("/conversations/{conversation_id}/messages")
def get_conversation_messages(
    conversation_id: str,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """대화 이력 (user+assistant, 시간순 오름차순). 앱이 폴링."""
    conv = db.query(Conversation).filter(Conversation.id == conversation_id).first()
    if conv and conv.user_id != user_id:
        raise HTTPException(status_code=403, detail="Not your conversation")

    rows = (
        db.query(ChatMessage)
        .filter(ChatMessage.conversation_id == conversation_id)
        .order_by(ChatMessage.turn_index.asc(), ChatMessage.id.asc())
        .all()
    )
    return {
        "messages": [
            {
                "role": m.role,
                "content": m.content,
                "turn_index": m.turn_index,
                "is_error": bool(getattr(m, "is_error", False)),
                "created_at": m.created_at.isoformat() if m.created_at else None,
            }
            for m in rows
        ]
    }


@router.get("/conversations")
def list_conversations(
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """대화 목록 (최신순)."""
    convs = (
        db.query(Conversation)
        .filter(Conversation.user_id == user_id)
        .order_by(Conversation.updated_at.desc())
        .limit(100)
        .all()
    )
    out = []
    for c in convs:
        last = (
            db.query(ChatMessage)
            .filter(ChatMessage.conversation_id == c.id)
            .order_by(ChatMessage.turn_index.desc())
            .first()
        )
        out.append({
            "conversation_id": c.id,
            "title": c.title,
            "last_message": last.content if last else None,
            "updated_at": c.updated_at.isoformat() if c.updated_at else None,
        })
    return {"conversations": out}

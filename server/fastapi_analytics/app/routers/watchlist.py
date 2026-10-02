"""
Watchlist router (authenticated Flutter endpoints).

관심종목 개인화 AI 의견 읽기. 데이터는 맥미니가 ingest 한 analytics.watchlist_opinion.
opinion 은 다국어 ||| 5세그먼트로 저장되며, 읽기 시 요청 lang 세그먼트만 추출해 내려준다.
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.database import get_db
from app.auth import get_current_user
from app.schemas import WatchlistOpinionListOut, WatchlistOpinionOut

router = APIRouter()

# 다국어 세그먼트 순서 — 앱/맥미니와 동일 (final_comment 포맷).
_SEG_ORDER = ['ko', 'en', 'zh', 'ja', 'es']


def _extract_lang(raw: str, lang: str) -> str:
    """||| 5세그먼트에서 요청 언어만 추출. 없으면 en → 첫 비어있지 않은 세그먼트."""
    if not raw:
        return ""
    if "|||" not in raw:
        return raw.strip()
    segs = raw.split("|||")

    def pick(l: str) -> str:
        i = _SEG_ORDER.index(l) if l in _SEG_ORDER else -1
        if 0 <= i < len(segs):
            s = segs[i].strip()
            if s:
                return s
        return ""

    return pick(lang) or pick("en") or next(
        (s.strip() for s in segs if s.strip()), ""
    )


@router.get("/opinion", response_model=WatchlistOpinionListOut)
def get_watchlist_opinions(
    lang: str = Query("en"),
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    내 관심종목 최신 개인화 AI 의견.
    종목별 opinion 이 비지 않은 최신 date 1건씩. opinion 은 요청 lang 추출본.
    """
    rows = db.execute(text(
        "SELECT DISTINCT ON (ticker) ticker, date, opinion, stance, confidence "
        "FROM analytics.watchlist_opinion "
        "WHERE user_id = :uid "
        "  AND opinion IS NOT NULL AND btrim(opinion) <> '' "
        "ORDER BY ticker, date DESC"
    ), {"uid": user_id}).fetchall()

    items = []
    for r in rows:
        body = _extract_lang(r.opinion or "", (lang or "en").lower())
        if not body:
            continue
        items.append(WatchlistOpinionOut(
            ticker=r.ticker,
            date=r.date.isoformat() if r.date else "",
            opinion=body,
            stance=r.stance,
            confidence=r.confidence,
        ))
    return WatchlistOpinionListOut(items=items)

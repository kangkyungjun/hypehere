"""
MarketLens FastAPI FCM 서비스
- Score ingest: ≥80 강력매수, ≤20 강력매도
- News ingest: bullish/bearish 뉴스
- Bullish News Surge: 주간 호재 급상승 30% 종목
- Cross-schema READ: Django public.accounts_* 테이블
"""
import logging
from datetime import date, timedelta

import firebase_admin
from firebase_admin import credentials, messaging
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.config import settings
from app.models import NotificationLog

logger = logging.getLogger(__name__)

_firebase_app = None


def _get_firebase_app():
    global _firebase_app
    if _firebase_app is None:
        try:
            _firebase_app = firebase_admin.get_app()
        except ValueError:
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            _firebase_app = firebase_admin.initialize_app(cred)
    return _firebase_app


# ─── Cross-schema helpers (Django public.* 테이블 읽기) ───

def _get_subscribed_tokens(db: Session, ticker: str):
    """
    해당 종목 구독자의 활성 FCM 토큰 + user_id 조회
    Returns: list of (user_id, token)
    """
    result = db.execute(text("""
        SELECT dt.user_id, dt.token
        FROM public.accounts_notificationsubscription ns
        JOIN public.accounts_devicetoken dt ON dt.user_id = ns.user_id AND dt.is_active = TRUE
        WHERE ns.ticker = :ticker AND ns.is_active = TRUE
    """), {"ticker": ticker.upper()})
    return result.fetchall()


def _get_all_active_tokens(db: Session):
    """전체 활성 토큰 조회 (MARKET 뉴스용)"""
    result = db.execute(text("""
        SELECT user_id, token
        FROM public.accounts_devicetoken
        WHERE is_active = TRUE
    """))
    return result.fetchall()


def _can_send_general(db: Session, user_id: int) -> bool:
    """1시간 이내 일반 알림 발송 여부 체크 (cross-schema)"""
    result = db.execute(text("""
        SELECT last_general_notified_at
        FROM public.accounts_notificationratelimit
        WHERE user_id = :user_id
    """), {"user_id": user_id})
    row = result.fetchone()
    if not row or not row[0]:
        return True
    from datetime import datetime, timezone as tz
    last = row[0]
    if last.tzinfo is None:
        from datetime import timezone as tz2
        last = last.replace(tzinfo=tz2.utc)
    now = datetime.now(tz.utc)
    return (now - last).total_seconds() >= 3600


def _update_rate_limit(db: Session, user_id: int):
    """발송 후 rate limit 갱신"""
    db.execute(text("""
        INSERT INTO public.accounts_notificationratelimit (user_id, last_general_notified_at)
        VALUES (:user_id, NOW())
        ON CONFLICT (user_id) DO UPDATE SET last_general_notified_at = NOW()
    """), {"user_id": user_id})


def _deactivate_invalid_tokens(db: Session, invalid_tokens: list):
    """만료/무효 토큰 비활성화"""
    if not invalid_tokens:
        return
    db.execute(text("""
        UPDATE public.accounts_devicetoken
        SET is_active = FALSE
        WHERE token = ANY(:tokens)
    """), {"tokens": invalid_tokens})
    logger.info(f"Deactivated {len(invalid_tokens)} invalid FCM tokens")


# ─── FCM 발송 ───

def _send_fcm(tokens: list, title: str, body: str, data: dict = None):
    """
    firebase-admin send_each() 배치 발송
    Returns: (success_count, failure_count, invalid_tokens)
    """
    if not tokens:
        return 0, 0, []

    _get_firebase_app()

    messages = [
        messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
            token=token,
        )
        for token in tokens
    ]

    invalid = []
    success = 0
    failure = 0

    for i in range(0, len(messages), 500):
        batch = messages[i:i + 500]
        batch_tokens = tokens[i:i + 500]
        try:
            response = messaging.send_each(batch)
            for j, resp in enumerate(response.responses):
                if resp.success:
                    success += 1
                else:
                    failure += 1
                    exc = resp.exception
                    if exc and hasattr(exc, 'code') and exc.code in (
                        'NOT_FOUND', 'UNREGISTERED', 'INVALID_ARGUMENT'
                    ):
                        invalid.append(batch_tokens[j])
        except Exception as e:
            logger.error(f"FCM send_each error: {e}")
            failure += len(batch)

    return success, failure, invalid


def _send_general_to_subscribers(db: Session, ticker: str, title: str, body: str, data: dict = None):
    """일반 알림: 종목 구독자에게 발송 (1시간 제한)"""
    rows = _get_subscribed_tokens(db, ticker)

    # user별 그룹핑
    user_tokens = {}
    for user_id, token in rows:
        user_tokens.setdefault(user_id, []).append(token)

    sent = 0
    all_invalid = []
    for user_id, tokens in user_tokens.items():
        if not _can_send_general(db, user_id):
            continue

        success, failure, invalid = _send_fcm(tokens, title, body, data)
        all_invalid.extend(invalid)
        if success > 0:
            _update_rate_limit(db, user_id)
            sent += 1

    if all_invalid:
        _deactivate_invalid_tokens(db, all_invalid)

    return sent


def _send_general_to_all(db: Session, title: str, body: str, data: dict = None):
    """일반 알림: 전체 사용자에게 발송 (1시간 제한)"""
    rows = _get_all_active_tokens(db)

    user_tokens = {}
    for user_id, token in rows:
        user_tokens.setdefault(user_id, []).append(token)

    sent = 0
    all_invalid = []
    for user_id, tokens in user_tokens.items():
        if not _can_send_general(db, user_id):
            continue

        success, failure, invalid = _send_fcm(tokens, title, body, data)
        all_invalid.extend(invalid)
        if success > 0:
            _update_rate_limit(db, user_id)
            sent += 1

    if all_invalid:
        _deactivate_invalid_tokens(db, all_invalid)

    return sent


# ─── 중복 방지 ───

def _already_notified(db: Session, today: date, ticker: str, signal_type: str) -> bool:
    """오늘 같은 (ticker, signal_type) 알림 이미 발송했는지"""
    result = db.execute(text("""
        SELECT 1 FROM analytics.notification_log
        WHERE date = :date AND ticker = :ticker AND signal_type = :signal_type
        LIMIT 1
    """), {"date": today, "ticker": ticker, "signal_type": signal_type})
    return result.fetchone() is not None


def _log_notification(db: Session, today: date, ticker: str, signal_type: str,
                      score: float = None, recipients: int = 0,
                      success: int = 0, failure: int = 0, error: str = None):
    """발송 로그 기록"""
    db.execute(text("""
        INSERT INTO analytics.notification_log
            (date, ticker, signal_type, score, recipients_count, success_count, failure_count, error_detail)
        VALUES (:date, :ticker, :signal_type, :score, :recipients, :success, :failure, :error)
    """), {
        "date": today, "ticker": ticker, "signal_type": signal_type,
        "score": score, "recipients": recipients,
        "success": success, "failure": failure, "error": error,
    })


# ─── Ingest 통합 함수 ───

def process_score_notifications(db: Session, today: date, ticker: str, score: float, signal: str):
    """
    Score ingest 후 알림 처리
    - score ≥ 80 → STRONG_BUY
    - score ≤ 20 → STRONG_SELL
    """
    if score is None:
        return

    if score >= 80:
        signal_type = "STRONG_BUY"
        title = f"[{ticker}] 강력 매수 시그널"
        body = f"Score {score:.0f} — {signal or 'BUY'}"
    elif score <= 20:
        signal_type = "STRONG_SELL"
        title = f"[{ticker}] 강력 매도 시그널"
        body = f"Score {score:.0f} — {signal or 'SELL'}"
    else:
        return

    if _already_notified(db, today, ticker, signal_type):
        return

    sent = _send_general_to_subscribers(db, ticker, title, body, data={
        "type": signal_type, "ticker": ticker, "score": str(int(score)),
    })
    _log_notification(db, today, ticker, signal_type, score=score, recipients=sent, success=sent)


def process_news_notifications(db: Session, today: date, ticker: str,
                               sentiment_grade: str, sentiment_score: int = 0,
                               ai_summary: str = None):
    """
    News ingest 후 알림 처리
    - bullish + score >= 85 → 강력 호재 뉴스
    - bearish + score <= -85 → 강력 악재 뉴스
    - MARKET ticker → 전체 사용자
    - 1시간 rate limit은 _send_general_to_subscribers에서 적용
    """
    if sentiment_grade not in ("bullish", "bearish"):
        return

    # 강한 감정 점수만 알림 발송 (약한 뉴스는 무시)
    if sentiment_grade == "bullish" and sentiment_score < 85:
        return
    if sentiment_grade == "bearish" and sentiment_score > -85:
        return

    signal_type = f"NEWS_{sentiment_grade.upper()}"

    if _already_notified(db, today, ticker, signal_type):
        return

    emoji = "📈" if sentiment_grade == "bullish" else "📉"
    label = "호재" if sentiment_grade == "bullish" else "악재"
    title = f"[{ticker}] {label} 뉴스 {emoji}"
    body = (ai_summary or "")[:120]

    if ticker == "MARKET":
        sent = _send_general_to_all(db, title, body, data={
            "type": "MARKET_NEWS", "sentiment": sentiment_grade,
        })
    else:
        sent = _send_general_to_subscribers(db, ticker, title, body, data={
            "type": signal_type, "ticker": ticker, "sentiment": sentiment_grade,
        })

    _log_notification(db, today, ticker, signal_type, recipients=sent, success=sent)


def process_bullish_surge_notifications(db: Session, today: date, tickers: list):
    """
    호재 뉴스 급상승 종목 감지 (주간 비교)
    - 지난주 bullish >= 3 AND 이번 주 대비 +30% 이상 → 알림
    """
    week_ago = today - timedelta(days=7)
    two_weeks_ago = today - timedelta(days=14)

    for ticker in tickers:
        if _already_notified(db, today, ticker, "BULLISH_NEWS_SURGE"):
            continue

        # 이번 주 bullish 수
        result = db.execute(text("""
            SELECT COUNT(*) FROM analytics.ticker_news
            WHERE ticker = :ticker AND date >= :week_ago AND sentiment_grade = 'bullish'
        """), {"ticker": ticker, "week_ago": week_ago})
        this_week = result.scalar() or 0

        # 지난주 bullish 수
        result = db.execute(text("""
            SELECT COUNT(*) FROM analytics.ticker_news
            WHERE ticker = :ticker AND date >= :two_weeks_ago AND date < :week_ago
                  AND sentiment_grade = 'bullish'
        """), {"ticker": ticker, "two_weeks_ago": two_weeks_ago, "week_ago": week_ago})
        last_week = result.scalar() or 0

        if last_week < 3:
            continue

        increase_pct = (this_week - last_week) / last_week * 100
        if increase_pct < 30:
            continue

        # 최신 bullish 뉴스 제목
        result = db.execute(text("""
            SELECT title FROM analytics.ticker_news
            WHERE ticker = :ticker AND date >= :week_ago AND sentiment_grade = 'bullish'
            ORDER BY date DESC, created_at DESC
            LIMIT 1
        """), {"ticker": ticker, "week_ago": week_ago})
        row = result.fetchone()
        latest_title = row[0][:60] if row else ""

        title = f"[{ticker}] 호재 뉴스 급상승"
        body = f"이번 주 호재 {this_week}건 (지난주 대비 +{increase_pct:.0f}%) — {latest_title}"

        sent = _send_general_to_subscribers(db, ticker, title, body, data={
            "type": "BULLISH_NEWS_SURGE",
            "ticker": ticker,
            "this_week": str(this_week),
            "last_week": str(last_week),
            "increase_pct": f"{increase_pct:.0f}",
        })
        _log_notification(db, today, ticker, "BULLISH_NEWS_SURGE",
                          score=increase_pct, recipients=sent, success=sent)


def process_daily_summary_notification(db: Session, today: date):
    """
    일일 시그널 요약 알림 — 모든 사용자에게 하루 1회 발송
    "강력매수 OO건, 강력매도 OO건을 확인해보세요"
    """
    # 오늘 이미 발송했으면 스킵
    if _already_notified(db, today, "ALL", "DAILY_SUMMARY"):
        return

    # 오늘 score ≥ 80 (강력매수) 개수
    result = db.execute(text("""
        SELECT COUNT(DISTINCT ticker) FROM analytics.ticker_scores
        WHERE date = :date AND score >= 80
    """), {"date": today})
    buy_count = result.scalar() or 0

    # 오늘 score ≤ 20 (강력매도) 개수
    result = db.execute(text("""
        SELECT COUNT(DISTINCT ticker) FROM analytics.ticker_scores
        WHERE date = :date AND score <= 20
    """), {"date": today})
    sell_count = result.scalar() or 0

    # 둘 다 0이면 발송 안 함
    if buy_count == 0 and sell_count == 0:
        return

    title = "오늘의 시그널 요약"
    body = f"강력매수 {buy_count}건, 강력매도 {sell_count}건을 확인해보세요"

    sent = _send_general_to_all(db, title, body, data={
        "type": "DAILY_SUMMARY",
        "buy_count": str(buy_count),
        "sell_count": str(sell_count),
        "date": str(today),
    })
    _log_notification(db, today, "ALL", "DAILY_SUMMARY",
                      recipients=sent, success=sent)

"""
MarketLens FastAPI FCM 서비스
- Score ingest: ≥80 강력매수, ≤20 강력매도
- News ingest: bullish/bearish 뉴스
- Bullish News Surge: 주간 호재 급상승 30% 종목
- Cross-schema READ: Django public.accounts_* 테이블
- 다국어 알림: DeviceToken.language 기반 (en/ko/ja/es)
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


# ─── 다국어 메시지 템플릿 (en/ko/ja/es) ───

MESSAGES = {
    "STRONG_BUY": {
        "en": ("[{ticker}] Strong Buy Signal", "Score {score} — {signal}"),
        "ko": ("[{ticker}] 강력 매수 시그널", "Score {score} — {signal}"),
        "ja": ("[{ticker}] 強力買いシグナル", "スコア {score} — {signal}"),
        "es": ("[{ticker}] Señal de compra fuerte", "Puntuación {score} — {signal}"),
    },
    "STRONG_SELL": {
        "en": ("[{ticker}] Strong Sell Signal", "Score {score} — {signal}"),
        "ko": ("[{ticker}] 강력 매도 시그널", "Score {score} — {signal}"),
        "ja": ("[{ticker}] 強力売りシグナル", "スコア {score} — {signal}"),
        "es": ("[{ticker}] Señal de venta fuerte", "Puntuación {score} — {signal}"),
    },
    "NEWS_BULLISH": {
        "en": ("[{ticker}] Bullish News 📈", "{summary}"),
        "ko": ("[{ticker}] 호재 뉴스 📈", "{summary}"),
        "ja": ("[{ticker}] 強気ニュース 📈", "{summary}"),
        "es": ("[{ticker}] Noticias alcistas 📈", "{summary}"),
    },
    "NEWS_BEARISH": {
        "en": ("[{ticker}] Bearish News 📉", "{summary}"),
        "ko": ("[{ticker}] 악재 뉴스 📉", "{summary}"),
        "ja": ("[{ticker}] 弱気ニュース 📉", "{summary}"),
        "es": ("[{ticker}] Noticias bajistas 📉", "{summary}"),
    },
    "BULLISH_NEWS_SURGE": {
        "en": ("[{ticker}] Bullish News Surge", "{this_week} bullish articles this week (+{increase_pct}%) — {headline}"),
        "ko": ("[{ticker}] 호재 뉴스 급상승", "이번 주 호재 {this_week}건 (지난주 대비 +{increase_pct}%) — {headline}"),
        "ja": ("[{ticker}] 強気ニュース急増", "今週の強気記事 {this_week}件 (先週比 +{increase_pct}%) — {headline}"),
        "es": ("[{ticker}] Aumento de noticias alcistas", "{this_week} noticias alcistas esta semana (+{increase_pct}%) — {headline}"),
    },
    "DAILY_SUMMARY": {
        "en": ("Today's Signal Summary", "Strong Buy: {buy_count}, Strong Sell: {sell_count} — Check now"),
        "ko": ("오늘의 시그널 요약", "강력매수 {buy_count}건, 강력매도 {sell_count}건을 확인해보세요"),
        "ja": ("本日のシグナル要約", "強力買い {buy_count}件、強力売り {sell_count}件 — 確認しましょう"),
        "es": ("Resumen de señales de hoy", "Compra fuerte: {buy_count}, Venta fuerte: {sell_count} — Revisa ahora"),
    },
}


def _get_msg(lang: str, key: str, **params) -> tuple:
    """언어별 메시지 포맷. 미지원 언어는 en 폴백."""
    templates = MESSAGES.get(key, {})
    title_tpl, body_tpl = templates.get(lang, templates.get("en", ("{ticker}", "")))
    return title_tpl.format(**params), body_tpl.format(**params)


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
    해당 종목 구독자의 활성 FCM 토큰 + user_id + language 조회
    Returns: list of (user_id, token, language)
    """
    result = db.execute(text("""
        SELECT dt.user_id, dt.token, COALESCE(dt.language, 'en') as language
        FROM public.accounts_notificationsubscription ns
        JOIN public.accounts_devicetoken dt ON dt.user_id = ns.user_id AND dt.is_active = TRUE
        WHERE ns.ticker = :ticker AND ns.is_active = TRUE
    """), {"ticker": ticker.upper()})
    return result.fetchall()


def _get_all_active_tokens(db: Session):
    """전체 활성 토큰 조회 (language 포함)"""
    result = db.execute(text("""
        SELECT user_id, token, COALESCE(language, 'en') as language
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


# ─── 알림 히스토리 저장 (cross-schema) ───

def _save_notification_history_bulk(db: Session, user_lang_entries: list):
    """
    rate limit 무관하게 모든 대상 사용자에게 알림 히스토리 저장
    user_lang_entries: [(user_id, title, body, notification_type, ticker), ...]
    """
    if not user_lang_entries:
        return
    # batch INSERT (500개씩)
    for i in range(0, len(user_lang_entries), 500):
        batch = user_lang_entries[i:i + 500]
        values_parts = []
        params = {}
        for j, (uid, title, body, ntype, ticker) in enumerate(batch):
            key = f"_{i}_{j}"
            values_parts.append(
                f"(:uid{key}, :title{key}, :body{key}, :ntype{key}, :ticker{key}, FALSE, NOW())"
            )
            params[f"uid{key}"] = uid
            params[f"title{key}"] = title
            params[f"body{key}"] = body
            params[f"ntype{key}"] = ntype
            params[f"ticker{key}"] = ticker or ''
        sql = f"""
            INSERT INTO public.accounts_notification_history
                (user_id, title, body, notification_type, ticker, is_read, created_at)
            VALUES {', '.join(values_parts)}
        """
        db.execute(text(sql), params)
    logger.info(f"Notification history saved: {len(user_lang_entries)} entries")


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


def _send_localized_to_subscribers(db: Session, ticker: str, msg_key: str, msg_params: dict, data: dict = None):
    """
    다국어 알림: 종목 구독자에게 언어별 발송 (1시간 제한)
    토큰을 (user_id, language)별로 그룹핑 → 언어별 메시지 생성 → 배치 발송
    """
    rows = _get_subscribed_tokens(db, ticker)

    # user_id → {language, tokens} 그룹핑
    user_info = {}
    for user_id, token, language in rows:
        if user_id not in user_info:
            user_info[user_id] = {"language": language, "tokens": []}
        user_info[user_id]["tokens"].append(token)

    # 히스토리 저장: rate limit 무관하게 모든 구독자 (언어별 title/body)
    history_entries = []
    for user_id, info in user_info.items():
        title, body = _get_msg(info["language"], msg_key, **msg_params)
        history_entries.append((user_id, title, body, msg_key, ticker.upper()))
    _save_notification_history_bulk(db, history_entries)

    sent = 0
    all_invalid = []
    for user_id, info in user_info.items():
        if not _can_send_general(db, user_id):
            continue

        title, body = _get_msg(info["language"], msg_key, **msg_params)
        success, failure, invalid = _send_fcm(info["tokens"], title, body, data)
        all_invalid.extend(invalid)
        if success > 0:
            _update_rate_limit(db, user_id)
            sent += 1

    if all_invalid:
        _deactivate_invalid_tokens(db, all_invalid)

    return sent


def _send_localized_to_all(db: Session, msg_key: str, msg_params: dict, data: dict = None):
    """다국어 알림: 전체 사용자에게 언어별 발송 (1시간 제한)"""
    rows = _get_all_active_tokens(db)

    user_info = {}
    for user_id, token, language in rows:
        if user_id not in user_info:
            user_info[user_id] = {"language": language, "tokens": []}
        user_info[user_id]["tokens"].append(token)

    # 히스토리 저장: rate limit 무관하게 전체 사용자 (언어별 title/body)
    history_entries = []
    for user_id, info in user_info.items():
        title, body = _get_msg(info["language"], msg_key, **msg_params)
        history_entries.append((user_id, title, body, msg_key, ''))
    _save_notification_history_bulk(db, history_entries)

    sent = 0
    all_invalid = []
    for user_id, info in user_info.items():
        if not _can_send_general(db, user_id):
            continue

        title, body = _get_msg(info["language"], msg_key, **msg_params)
        success, failure, invalid = _send_fcm(info["tokens"], title, body, data)
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
    elif score <= 20:
        signal_type = "STRONG_SELL"
    else:
        return

    if _already_notified(db, today, ticker, signal_type):
        return

    params = {"ticker": ticker, "score": f"{score:.0f}", "signal": signal or ("BUY" if score >= 80 else "SELL")}

    sent = _send_localized_to_subscribers(db, ticker, signal_type, params, data={
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
    """
    if sentiment_grade not in ("bullish", "bearish"):
        return

    if sentiment_grade == "bullish" and sentiment_score < 85:
        return
    if sentiment_grade == "bearish" and sentiment_score > -85:
        return

    signal_type = f"NEWS_{sentiment_grade.upper()}"

    if _already_notified(db, today, ticker, signal_type):
        return

    params = {"ticker": ticker, "summary": (ai_summary or "")[:120]}

    if ticker == "MARKET":
        sent = _send_localized_to_all(db, signal_type, params, data={
            "type": "MARKET_NEWS", "sentiment": sentiment_grade,
        })
    else:
        sent = _send_localized_to_subscribers(db, ticker, signal_type, params, data={
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

        result = db.execute(text("""
            SELECT COUNT(*) FROM analytics.ticker_news
            WHERE ticker = :ticker AND date >= :week_ago AND sentiment_grade = 'bullish'
        """), {"ticker": ticker, "week_ago": week_ago})
        this_week = result.scalar() or 0

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

        result = db.execute(text("""
            SELECT title FROM analytics.ticker_news
            WHERE ticker = :ticker AND date >= :week_ago AND sentiment_grade = 'bullish'
            ORDER BY date DESC, created_at DESC
            LIMIT 1
        """), {"ticker": ticker, "week_ago": week_ago})
        row = result.fetchone()
        headline = row[0][:60] if row else ""

        params = {"ticker": ticker, "this_week": str(this_week), "increase_pct": f"{increase_pct:.0f}", "headline": headline}

        sent = _send_localized_to_subscribers(db, ticker, "BULLISH_NEWS_SURGE", params, data={
            "type": "BULLISH_NEWS_SURGE", "ticker": ticker,
            "this_week": str(this_week), "last_week": str(last_week),
            "increase_pct": f"{increase_pct:.0f}",
        })
        _log_notification(db, today, ticker, "BULLISH_NEWS_SURGE",
                          score=increase_pct, recipients=sent, success=sent)


def process_daily_summary_notification(db: Session, today: date):
    """일일 시그널 요약 알림 — 모든 사용자에게 하루 1회 발송"""
    if _already_notified(db, today, "ALL", "DAILY_SUMMARY"):
        return

    result = db.execute(text("""
        SELECT COUNT(DISTINCT ticker) FROM analytics.ticker_scores
        WHERE date = :date AND score >= 80
    """), {"date": today})
    buy_count = result.scalar() or 0

    result = db.execute(text("""
        SELECT COUNT(DISTINCT ticker) FROM analytics.ticker_scores
        WHERE date = :date AND score <= 20
    """), {"date": today})
    sell_count = result.scalar() or 0

    if buy_count == 0 and sell_count == 0:
        return

    params = {"buy_count": str(buy_count), "sell_count": str(sell_count)}

    sent = _send_localized_to_all(db, "DAILY_SUMMARY", params, data={
        "type": "DAILY_SUMMARY",
        "buy_count": str(buy_count),
        "sell_count": str(sell_count),
        "date": str(today),
    })
    _log_notification(db, today, "ALL", "DAILY_SUMMARY",
                      recipients=sent, success=sent)

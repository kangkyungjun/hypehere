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
        "zh": ("[{ticker}] 强力买入信号", "评分 {score} — {signal}"),
        "es": ("[{ticker}] Señal de compra fuerte", "Puntuación {score} — {signal}"),
    },
    "STRONG_SELL": {
        "en": ("[{ticker}] Strong Sell Signal", "Score {score} — {signal}"),
        "ko": ("[{ticker}] 강력 매도 시그널", "Score {score} — {signal}"),
        "ja": ("[{ticker}] 強力売りシグナル", "スコア {score} — {signal}"),
        "zh": ("[{ticker}] 强力卖出信号", "评分 {score} — {signal}"),
        "es": ("[{ticker}] Señal de venta fuerte", "Puntuación {score} — {signal}"),
    },
    "NEWS_BULLISH": {
        "en": ("[{ticker}] Bullish News 📈", "{summary}"),
        "ko": ("[{ticker}] 호재 뉴스 📈", "{summary}"),
        "ja": ("[{ticker}] 強気ニュース 📈", "{summary}"),
        "zh": ("[{ticker}] 利好消息 📈", "{summary}"),
        "es": ("[{ticker}] Noticias alcistas 📈", "{summary}"),
    },
    "NEWS_BEARISH": {
        "en": ("[{ticker}] Bearish News 📉", "{summary}"),
        "ko": ("[{ticker}] 악재 뉴스 📉", "{summary}"),
        "ja": ("[{ticker}] 弱気ニュース 📉", "{summary}"),
        "zh": ("[{ticker}] 利空消息 📉", "{summary}"),
        "es": ("[{ticker}] Noticias bajistas 📉", "{summary}"),
    },
    "BULLISH_NEWS_SURGE": {
        "en": ("[{ticker}] Bullish News Surge", "{this_week} bullish articles this week (+{increase_pct}%) — {headline}"),
        "ko": ("[{ticker}] 호재 뉴스 급상승", "이번 주 호재 {this_week}건 (지난주 대비 +{increase_pct}%) — {headline}"),
        "ja": ("[{ticker}] 強気ニュース急増", "今週の強気記事 {this_week}件 (先週比 +{increase_pct}%) — {headline}"),
        "zh": ("[{ticker}] 利好消息激增", "本周利好 {this_week}篇 (较上周 +{increase_pct}%) — {headline}"),
        "es": ("[{ticker}] Aumento de noticias alcistas", "{this_week} noticias alcistas esta semana (+{increase_pct}%) — {headline}"),
    },
    "DAILY_SUMMARY": {
        "en": ("Today's #1: {top_ticker} (Score {top_score})", "{buy_count} Buy, {sell_count} Sell, {hold_count} Hold signals. Check the app for details!"),
        "ko": ("오늘의 1위: {top_ticker} (Score {top_score})", "매수 {buy_count}건, 매도 {sell_count}건, 관망 {hold_count}건. 앱에서 확인하세요!"),
        "ja": ("本日1位: {top_ticker} (Score {top_score})", "買い {buy_count}件、売り {sell_count}件、様子見 {hold_count}件。アプリで確認！"),
        "zh": ("今日第一: {top_ticker} (评分 {top_score})", "买入 {buy_count}个, 卖出 {sell_count}个, 观望 {hold_count}个。打开应用查看详情！"),
        "es": ("Hoy #1: {top_ticker} (Score {top_score})", "Compra {buy_count}, Venta {sell_count}, Espera {hold_count}. Revisa la app!"),
    },
    "MORNING_BRIEFING": {
        "en": ("Market Recap: S&P 500 {spy_change}%", "Top Gainer: {top_gainer} {gainer_change}%. {buy_count} Buy signals today."),
        "ko": ("시장 요약: S&P 500 {spy_change}%", "최대 상승: {top_gainer} {gainer_change}%. 오늘 매수 시그널 {buy_count}건."),
        "ja": ("市場まとめ: S&P 500 {spy_change}%", "最大上昇: {top_gainer} {gainer_change}%。本日の買いシグナル {buy_count}件。"),
        "zh": ("市场回顾: S&P 500 {spy_change}%", "最大涨幅: {top_gainer} {gainer_change}%。今日买入信号 {buy_count}个。"),
        "es": ("Resumen: S&P 500 {spy_change}%", "Mayor subida: {top_gainer} {gainer_change}%. {buy_count} señales de compra hoy."),
    },
    "CLOSING_REPORT": {
        "en": ("Market Closed: {top_gainer} {gainer_change}%", "Top Score: {top_ticker} ({top_score}). {top_loser} {loser_change}%."),
        "ko": ("장 마감: {top_gainer} {gainer_change}%", "최고 스코어: {top_ticker} ({top_score}). {top_loser} {loser_change}%."),
        "ja": ("市場終了: {top_gainer} {gainer_change}%", "最高スコア: {top_ticker} ({top_score})。{top_loser} {loser_change}%。"),
        "zh": ("收盘: {top_gainer} {gainer_change}%", "最高评分: {top_ticker} ({top_score})。{top_loser} {loser_change}%。"),
        "es": ("Mercado cerrado: {top_gainer} {gainer_change}%", "Mejor puntaje: {top_ticker} ({top_score}). {top_loser} {loser_change}%."),
    },
    "MARKET_OPEN": {
        "en": ("Market Open! {earnings_count} Earnings Today", "Yesterday's Top: {top_ticker} (Score {top_score}). {buy_count} Buy signals active."),
        "ko": ("시장 개장! 오늘 실적발표 {earnings_count}건", "어제 1위: {top_ticker} (Score {top_score}). 매수 시그널 {buy_count}건 활성."),
        "ja": ("市場開場！本日の決算 {earnings_count}件", "昨日1位: {top_ticker} (Score {top_score})。買いシグナル {buy_count}件。"),
        "zh": ("开盘！今日财报 {earnings_count}家", "昨日第一: {top_ticker} (评分 {top_score})。买入信号 {buy_count}个。"),
        "es": ("Mercado abierto! {earnings_count} reportes hoy", "Ayer #1: {top_ticker} (Score {top_score}). {buy_count} señales de compra."),
    },
    "BREAKING_NEWS": {
        "en": ("[{ticker}] Breaking News", "{summary}"),
        "ko": ("[{ticker}] 속보", "{summary}"),
        "ja": ("[{ticker}] 速報", "{summary}"),
        "zh": ("[{ticker}] 突发新闻", "{summary}"),
        "es": ("[{ticker}] Última hora", "{summary}"),
    },
    "PORTFOLIO_ADVICE": {
        "en": ("Portfolio AI Analysis Complete", "Your portfolio analysis is ready. Check it out!"),
        "ko": ("포트폴리오 AI 분석 완료", "전체 포트폴리오 분석이 완료되었습니다. 확인해보세요!"),
        "ja": ("ポートフォリオAI分析完了", "ポートフォリオ全体の分析が完了しました。確認してください！"),
        "zh": ("投资组合AI分析完成", "投资组合分析已完成，请查看！"),
        "es": ("Análisis AI del portafolio listo", "¡El análisis de tu portafolio está listo!"),
    },
    "EARNINGS_REMINDER": {
        "en": ("Earnings Tomorrow: {tickers}", "{count} stocks in your watchlist report earnings tomorrow."),
        "ko": ("내일 실적발표: {tickers}", "워치리스트 종목 {count}개가 내일 실적을 발표합니다."),
        "ja": ("明日決算発表: {tickers}", "ウォッチリストの{count}銘柄が明日決算を発表します。"),
        "zh": ("明日财报: {tickers}", "您关注的{count}只股票明日发布财报。"),
        "es": ("Resultados mañana: {tickers}", "{count} acciones de tu lista reportan resultados mañana."),
    },
    "WATCHLIST_MOVERS": {
        "en": ("Watchlist Alert: {tickers}", "{count} stocks in your watchlist moved significantly today."),
        "ko": ("워치리스트 알림: {tickers}", "관심 종목 중 {count}개가 오늘 크게 움직였습니다."),
        "ja": ("ウォッチリスト通知: {tickers}", "ウォッチリストの{count}銘柄が本日大きく変動しました。"),
        "zh": ("关注列表提醒: {tickers}", "您关注的{count}只股票今日大幅波动。"),
        "es": ("Alerta de lista: {tickers}", "{count} acciones de tu lista tuvieron grandes movimientos hoy."),
    },
    "SCORE_CHANGE": {
        "en": ("[{ticker}] Score {direction}: {old_score} → {new_score}", "AI score {verb} {delta} points. {signal_hint}"),
        "ko": ("[{ticker}] 스코어 {direction}: {old_score} → {new_score}", "AI 스코어가 {delta}포인트 {verb}. {signal_hint}"),
        "ja": ("[{ticker}] スコア{direction}: {old_score} → {new_score}", "AIスコアが{delta}ポイント{verb}。{signal_hint}"),
        "zh": ("[{ticker}] 评分{direction}: {old_score} → {new_score}", "AI评分{verb}{delta}分。{signal_hint}"),
        "es": ("[{ticker}] Puntuación {direction}: {old_score} → {new_score}", "Puntuación AI {verb} {delta} puntos. {signal_hint}"),
    },
    "PORTFOLIO_DAILY": {
        "en": ("Portfolio: {day_pnl} ({day_pnl_pct}%)", "Best: {best_ticker} {best_pct}% | Worst: {worst_ticker} {worst_pct}%"),
        "ko": ("포트폴리오: {day_pnl} ({day_pnl_pct}%)", "최고: {best_ticker} {best_pct}% | 최저: {worst_ticker} {worst_pct}%"),
        "ja": ("ポートフォリオ: {day_pnl} ({day_pnl_pct}%)", "最高: {best_ticker} {best_pct}% | 最低: {worst_ticker} {worst_pct}%"),
        "zh": ("投资组合: {day_pnl} ({day_pnl_pct}%)", "最佳: {best_ticker} {best_pct}% | 最差: {worst_ticker} {worst_pct}%"),
        "es": ("Portafolio: {day_pnl} ({day_pnl_pct}%)", "Mejor: {best_ticker} {best_pct}% | Peor: {worst_ticker} {worst_pct}%"),
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


def _send_localized_to_all(db: Session, msg_key: str, msg_params: dict,
                           data: dict = None, skip_rate_limit: bool = False):
    """
    다국어 알림: 전체 사용자에게 언어별 발송
    skip_rate_limit=True: 예약 브로드캐스트용 — rate limit 체크/갱신 건너뜀
    """
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
        if not skip_rate_limit and not _can_send_general(db, user_id):
            continue

        title, body = _get_msg(info["language"], msg_key, **msg_params)
        success, failure, invalid = _send_fcm(info["tokens"], title, body, data)
        all_invalid.extend(invalid)
        if success > 0:
            if not skip_rate_limit:
                _update_rate_limit(db, user_id)
            sent += 1

    if all_invalid:
        _deactivate_invalid_tokens(db, all_invalid)

    return sent


def _send_personalized_per_user(db: Session, user_notifications: list,
                                 notification_type: str,
                                 skip_rate_limit: bool = True) -> int:
    """
    사용자별 개인화된 내용 발송.
    user_notifications: [
        {"user_id": int, "tokens": [str], "language": str,
         "msg_params": dict, "ticker": str, "data": dict},
        ...
    ]
    """
    if not user_notifications:
        return 0

    # 1) 히스토리 저장 (rate limit 무관)
    history_entries = []
    for un in user_notifications:
        title, body = _get_msg(un["language"], notification_type, **un["msg_params"])
        history_entries.append((
            un["user_id"], title, body, notification_type, un.get("ticker", ""),
        ))
    _save_notification_history_bulk(db, history_entries)

    # 2) FCM 발송
    sent = 0
    all_invalid = []
    for un in user_notifications:
        if not skip_rate_limit and not _can_send_general(db, un["user_id"]):
            continue

        title, body = _get_msg(un["language"], notification_type, **un["msg_params"])
        success, failure, invalid = _send_fcm(un["tokens"], title, body, un.get("data"))
        all_invalid.extend(invalid)
        if success > 0:
            if not skip_rate_limit:
                _update_rate_limit(db, un["user_id"])
            sent += 1

    # 3) 무효 토큰 비활성화
    if all_invalid:
        _deactivate_invalid_tokens(db, all_invalid)

    return sent


# ─── 개인화 알림 유틸리티 ───

def _get_next_trading_date(from_date: date) -> date:
    """다음 거래일 계산 (주말 + NYSE 휴일 건너뜀)"""
    d = from_date + timedelta(days=1)
    while not _is_us_trading_day(d):
        d += timedelta(days=1)
    return d


def _format_ticker_list(tickers: list, max_display: int = 3) -> str:
    """종목 리스트를 표시용 문자열로 변환 (초과 시 +N 표시)"""
    if not tickers:
        return ""
    if len(tickers) <= max_display:
        return ", ".join(tickers)
    return ", ".join(tickers[:max_display]) + f" +{len(tickers) - max_display}"


def _extract_best_worst(holdings_detail) -> tuple:
    """
    JSONB holdings_detail에서 최고/최저 수익 종목 추출.
    Returns: (best_ticker, best_pct, worst_ticker, worst_pct)
    """
    if not holdings_detail or not isinstance(holdings_detail, list):
        return ("--", "0.0", "--", "0.0")

    best = max(holdings_detail, key=lambda h: float(h.get("day_change_pct", 0) or 0), default=None)
    worst = min(holdings_detail, key=lambda h: float(h.get("day_change_pct", 0) or 0), default=None)

    if not best or not worst:
        return ("--", "0.0", "--", "0.0")

    return (
        best.get("ticker", "--"),
        f"{float(best.get('day_change_pct', 0) or 0):+.1f}",
        worst.get("ticker", "--"),
        f"{float(worst.get('day_change_pct', 0) or 0):+.1f}",
    )


# ─── SCORE_CHANGE 다국어 상수 ───

_SCORE_CHANGE_WORDS = {
    "en": {"up": "↑", "down": "↓", "surged": "surged", "dropped": "dropped"},
    "ko": {"up": "↑", "down": "↓", "surged": "급등", "dropped": "급락"},
    "ja": {"up": "↑", "down": "↓", "surged": "急騰", "dropped": "急落"},
    "zh": {"up": "↑", "down": "↓", "surged": "飙升", "dropped": "骤降"},
    "es": {"up": "↑", "down": "↓", "surged": "subió", "dropped": "bajó"},
}

_SIGNAL_HINTS = {
    "en": {
        "strong_buy": "Approaching strong buy signal.",
        "strong_sell": "Approaching strong sell signal.",
        "neutral": "Score changed significantly.",
    },
    "ko": {
        "strong_buy": "매수 시그널에 근접 중.",
        "strong_sell": "매도 시그널에 근접 중.",
        "neutral": "스코어가 크게 변동했습니다.",
    },
    "ja": {
        "strong_buy": "買いシグナルに接近中。",
        "strong_sell": "売りシグナルに接近中。",
        "neutral": "スコアが大きく変動しました。",
    },
    "zh": {
        "strong_buy": "接近强力买入信号。",
        "strong_sell": "接近强力卖出信号。",
        "neutral": "评分大幅变动。",
    },
    "es": {
        "strong_buy": "Acercándose a señal de compra fuerte.",
        "strong_sell": "Acercándose a señal de venta fuerte.",
        "neutral": "Puntuación cambió significativamente.",
    },
}


def _get_score_change_params(lang: str, ticker: str, old_score: int, new_score: int) -> dict:
    """SCORE_CHANGE 메시지 파라미터 빌더"""
    words = _SCORE_CHANGE_WORDS.get(lang, _SCORE_CHANGE_WORDS["en"])
    hints = _SIGNAL_HINTS.get(lang, _SIGNAL_HINTS["en"])

    delta = new_score - old_score
    is_up = delta > 0
    direction = words["up"] if is_up else words["down"]
    verb = words["surged"] if is_up else words["dropped"]

    if new_score >= 70:
        signal_hint = hints["strong_buy"]
    elif new_score <= 30:
        signal_hint = hints["strong_sell"]
    else:
        signal_hint = hints["neutral"]

    return {
        "ticker": ticker,
        "direction": direction,
        "old_score": str(old_score),
        "new_score": str(new_score),
        "delta": str(abs(delta)),
        "verb": verb,
        "signal_hint": signal_hint,
    }


def _get_user_tokens_map(db: Session, user_ids: list) -> dict:
    """사용자 ID 목록에 대한 토큰 + 언어 맵 조회.
    Returns: {user_id: {"tokens": [...], "language": str}}
    """
    if not user_ids:
        return {}
    result = db.execute(text("""
        SELECT user_id, token, COALESCE(language, 'en') as language
        FROM public.accounts_devicetoken
        WHERE is_active = TRUE AND user_id = ANY(:user_ids)
    """), {"user_ids": user_ids})

    user_map = {}
    for user_id, token, language in result.fetchall():
        if user_id not in user_map:
            user_map[user_id] = {"tokens": [], "language": language}
        user_map[user_id]["tokens"].append(token)
    return user_map


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
                               ai_summary: str = None, title: str = None,
                               source_url: str = None):
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

    # Flutter 뉴스 모달 표시를 위한 추가 데이터
    extra = {}
    if title:
        extra["title"] = title[:120]
    if ai_summary:
        extra["ai_summary"] = ai_summary[:200]
    if source_url:
        extra["source_url"] = source_url

    if ticker == "MARKET":
        sent = _send_localized_to_all(db, signal_type, params, data={
            "type": "MARKET_NEWS", "sentiment": sentiment_grade,
            "ticker": "MARKET", **extra,
        })
    else:
        sent = _send_localized_to_subscribers(db, ticker, signal_type, params, data={
            "type": signal_type, "ticker": ticker, "sentiment": sentiment_grade,
            **extra,
        })

    _log_notification(db, today, ticker, signal_type, recipients=sent, success=sent)


def process_breaking_news_notification(db: Session, today: date, ticker: str,
                                       ai_summary: str = None, source_url: str = None,
                                       title: str = None):
    """
    속보 뉴스 알림 — 전체 사용자 즉시 broadcast (1시간 제한 무시).
    is_breaking=True인 뉴스가 ingest될 때 호출.
    """
    signal_type = "BREAKING_NEWS"

    if _already_notified(db, today, ticker, signal_type):
        return

    params = {"ticker": ticker, "summary": (ai_summary or "")[:120]}
    data = {
        "type": "BREAKING_NEWS",
        "ticker": ticker,
    }
    if title:
        data["title"] = title[:120]
    if ai_summary:
        data["ai_summary"] = ai_summary[:200]
    if source_url:
        data["source_url"] = source_url

    sent = _send_localized_to_all(db, signal_type, params, data=data,
                                  skip_rate_limit=True)
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
    """
    일일 시그널 요약 — 오늘의 1위 종목 + 시그널 분포
    Triggered during score ingest
    """
    if _already_notified(db, today, "ALL", "DAILY_SUMMARY"):
        return

    scorer = _get_top_scorer(db, today)
    if not scorer:
        logger.info(f"DAILY_SUMMARY skipped: no score data for {today}")
        return

    top_ticker, top_score = scorer
    buy_count, sell_count, hold_count = _get_signal_distribution(db, today)

    params = {
        "top_ticker": top_ticker, "top_score": str(top_score),
        "buy_count": str(buy_count), "sell_count": str(sell_count),
        "hold_count": str(hold_count),
    }

    sent = _send_localized_to_all(db, "DAILY_SUMMARY", params, data={
        "type": "DAILY_SUMMARY", "top_ticker": top_ticker, "date": str(today),
    }, skip_rate_limit=True)
    _log_notification(db, today, "ALL", "DAILY_SUMMARY",
                      recipients=sent, success=sent)


def _get_last_trading_date(db: Session, up_to: date = None):
    """DB에 실제 데이터가 있는 가장 최근 거래일 반환 (타임존 무관)"""
    if up_to:
        result = db.execute(text("""
            SELECT MAX(date) FROM analytics.ticker_scores
            WHERE date <= :up_to
        """), {"up_to": up_to})
    else:
        result = db.execute(text("""
            SELECT MAX(date) FROM analytics.ticker_scores
        """))
    row = result.fetchone()
    return row[0] if row and row[0] else None


def _get_top_scorer(db: Session, target_date: date):
    """해당 날짜의 최고 점수 종목 (ticker, score) — 데이터 없으면 None"""
    result = db.execute(text("""
        SELECT ticker, score FROM analytics.ticker_scores
        WHERE date = :date
        ORDER BY score DESC LIMIT 1
    """), {"date": target_date})
    row = result.fetchone()
    return (row[0], int(row[1])) if row else None


def _get_signal_distribution(db: Session, target_date: date):
    """해당 날짜의 시그널 분포 (buy, sell, hold)"""
    result = db.execute(text("""
        SELECT
            COUNT(DISTINCT CASE WHEN score >= 60 THEN ticker END),
            COUNT(DISTINCT CASE WHEN score <= 40 THEN ticker END),
            COUNT(DISTINCT CASE WHEN score > 40 AND score < 60 THEN ticker END)
        FROM analytics.ticker_scores
        WHERE date = :date
    """), {"date": target_date})
    row = result.fetchone()
    return (row[0] or 0, row[1] or 0, row[2] or 0) if row else (0, 0, 0)


def _get_top_gainer_loser(db: Session, target_date: date):
    """해당 날짜의 최대 상승/하락 종목"""
    result = db.execute(text("""
        SELECT ticker, change_pct FROM analytics.ticker_prices
        WHERE date = :date AND change_pct IS NOT NULL
        ORDER BY change_pct DESC LIMIT 1
    """), {"date": target_date})
    gainer_row = result.fetchone()

    result = db.execute(text("""
        SELECT ticker, change_pct FROM analytics.ticker_prices
        WHERE date = :date AND change_pct IS NOT NULL
        ORDER BY change_pct ASC LIMIT 1
    """), {"date": target_date})
    loser_row = result.fetchone()

    gainer = (gainer_row[0], f"{gainer_row[1]:+.1f}") if gainer_row else None
    loser = (loser_row[0], f"{loser_row[1]:+.1f}") if loser_row else None
    return gainer, loser


def _get_spy_change(db: Session, target_date: date):
    """SPY 변동률 조회"""
    result = db.execute(text("""
        SELECT change_pct FROM analytics.ticker_prices
        WHERE date = :date AND ticker = 'SPY'
    """), {"date": target_date})
    row = result.fetchone()
    return f"{row[0]:+.1f}" if row and row[0] is not None else None


# ─── NYSE 휴일 캘린더 (2025-2027) ───

_NYSE_HOLIDAYS = {
    # 2025
    date(2025, 1, 1),    # New Year's Day
    date(2025, 1, 20),   # MLK Jr. Day
    date(2025, 2, 17),   # Presidents' Day
    date(2025, 4, 18),   # Good Friday
    date(2025, 5, 26),   # Memorial Day
    date(2025, 6, 19),   # Juneteenth
    date(2025, 7, 4),    # Independence Day
    date(2025, 9, 1),    # Labor Day
    date(2025, 11, 27),  # Thanksgiving
    date(2025, 12, 25),  # Christmas
    # 2026
    date(2026, 1, 1),    # New Year's Day
    date(2026, 1, 19),   # MLK Jr. Day
    date(2026, 2, 16),   # Presidents' Day
    date(2026, 4, 3),    # Good Friday
    date(2026, 5, 25),   # Memorial Day
    date(2026, 6, 19),   # Juneteenth
    date(2026, 7, 3),    # Independence Day (observed)
    date(2026, 9, 7),    # Labor Day
    date(2026, 11, 26),  # Thanksgiving
    date(2026, 12, 25),  # Christmas
    # 2027
    date(2027, 1, 1),    # New Year's Day
    date(2027, 1, 18),   # MLK Jr. Day
    date(2027, 2, 15),   # Presidents' Day
    date(2027, 3, 26),   # Good Friday
    date(2027, 5, 31),   # Memorial Day
    date(2027, 6, 18),   # Juneteenth (observed)
    date(2027, 7, 5),    # Independence Day (observed)
    date(2027, 9, 6),    # Labor Day
    date(2027, 11, 25),  # Thanksgiving
    date(2027, 12, 24),  # Christmas (observed)
}


def _is_us_trading_day(d: date) -> bool:
    """주말 + NYSE 공휴일 제외"""
    return d.weekday() < 5 and d not in _NYSE_HOLIDAYS


def process_morning_briefing(db: Session):
    """
    아침 브리핑 — S&P 500 변동 + 최대 상승종목 + 매수 시그널 수
    Triggered at 22:00 UTC (17:00 EST / 07:00 KST+1)
    """
    today = date.today()
    last_trading_day = _get_last_trading_date(db, today)
    if not last_trading_day:
        logger.info("MORNING_BRIEFING skipped: no trading data found")
        return

    if _already_notified(db, last_trading_day, "ALL", "MORNING_BRIEFING"):
        return

    spy_change = _get_spy_change(db, last_trading_day)
    gainer, _ = _get_top_gainer_loser(db, last_trading_day)
    if not spy_change or not gainer:
        logger.info(f"MORNING_BRIEFING skipped: incomplete data for {last_trading_day}")
        return

    top_gainer, gainer_change = gainer
    buy_count, _, _ = _get_signal_distribution(db, last_trading_day)

    params = {
        "spy_change": spy_change,
        "top_gainer": top_gainer, "gainer_change": gainer_change,
        "buy_count": str(buy_count),
    }

    sent = _send_localized_to_all(db, "MORNING_BRIEFING", params, data={
        "type": "MORNING_BRIEFING", "date": str(last_trading_day),
        "top_ticker": top_gainer,
    }, skip_rate_limit=True)
    _log_notification(db, last_trading_day, "ALL", "MORNING_BRIEFING",
                      recipients=sent, success=sent)


def process_closing_report(db: Session, today: date):
    """
    장 마감 리포트 — 상승/하락 1위 + 최고 스코어
    Triggered at 11:45 UTC (06:45 EST / 20:45 KST)
    today = UTC date (서버 기준). 데이터는 미국 거래일 기준이므로 DB에서 최근 거래일을 조회.
    """
    trading_date = _get_last_trading_date(db, today)
    if not trading_date:
        logger.info(f"CLOSING_REPORT skipped: no trading data found up to {today}")
        return

    if _already_notified(db, trading_date, "ALL", "CLOSING_REPORT"):
        return

    gainer, loser = _get_top_gainer_loser(db, trading_date)
    scorer = _get_top_scorer(db, trading_date)
    if not gainer or not scorer:
        logger.info(f"CLOSING_REPORT skipped: incomplete data for {trading_date}")
        return

    top_gainer, gainer_change = gainer
    top_loser, loser_change = loser if loser else ("—", "0.0")
    top_ticker, top_score = scorer

    params = {
        "top_gainer": top_gainer, "gainer_change": gainer_change,
        "top_loser": top_loser, "loser_change": loser_change,
        "top_ticker": top_ticker, "top_score": str(top_score),
    }

    sent = _send_localized_to_all(db, "CLOSING_REPORT", params, data={
        "type": "CLOSING_REPORT", "date": str(trading_date),
        "top_ticker": top_ticker,
    }, skip_rate_limit=True)
    _log_notification(db, trading_date, "ALL", "CLOSING_REPORT",
                      recipients=sent, success=sent)


def process_market_open(db: Session, today: date):
    """
    시장 개장 알림 — 어닝 예정 + 어제 1위 종목
    Triggered at 14:35 UTC (09:35 EST / 23:35 KST)
    """
    if not _is_us_trading_day(today):
        logger.info(f"MARKET_OPEN skipped: {today} is not a US trading day")
        return

    if _already_notified(db, today, "ALL", "MARKET_OPEN"):
        return

    # 오늘 어닝 발표 건수
    result = db.execute(text("""
        SELECT COUNT(*) FROM analytics.earnings_week_events
        WHERE earnings_date = :today
    """), {"today": today})
    earnings_count = result.scalar() or 0

    # 최근 거래일의 1위 종목 + 활성 매수 시그널 수
    last_date = _get_last_trading_date(db)
    if not last_date:
        logger.info("MARKET_OPEN skipped: no trading data found")
        return

    scorer = _get_top_scorer(db, last_date)
    if not scorer:
        logger.info(f"MARKET_OPEN skipped: incomplete data for {last_date}")
        return

    top_ticker, top_score = scorer
    buy_count, _, _ = _get_signal_distribution(db, last_date)

    params = {
        "earnings_count": str(earnings_count),
        "top_ticker": top_ticker, "top_score": str(top_score),
        "buy_count": str(buy_count),
    }

    sent = _send_localized_to_all(db, "MARKET_OPEN", params, data={
        "type": "MARKET_OPEN", "date": str(last_date),
        "top_ticker": top_ticker,
    }, skip_rate_limit=True)
    _log_notification(db, today, "ALL", "MARKET_OPEN",
                      recipients=sent, success=sent)


def send_portfolio_advice_notification(db: Session, user_id: int):
    """
    포트폴리오 AI 분석 완료 후 해당 유저에게 FCM 발송.
    1시간 rate limit 적용.
    """
    rows = db.execute(text("""
        SELECT dt.token, COALESCE(dt.language, 'en') as language
        FROM public.accounts_devicetoken dt
        WHERE dt.user_id = :user_id AND dt.is_active = TRUE
    """), {"user_id": user_id}).fetchall()

    if not rows:
        return

    if not _can_send_general(db, user_id):
        logger.info(f"Portfolio advice FCM skipped (rate limit): user={user_id}")
        return

    language = rows[0].language
    tokens = [r.token for r in rows]
    title, body = _get_msg(language, "PORTFOLIO_ADVICE")

    # Save notification history
    _save_notification_history_bulk(db, [
        (user_id, title, body, "PORTFOLIO_ADVICE", ''),
    ])

    success, failure, invalid = _send_fcm(tokens, title, body, data={
        "type": "PORTFOLIO_ADVICE",
    })

    if success > 0:
        _update_rate_limit(db, user_id)

    if invalid:
        _deactivate_invalid_tokens(db, invalid)

    logger.info(f"Portfolio advice FCM sent: user={user_id}, success={success}, failure={failure}")


# ─── 개인화 알림 process 함수 (Phase 1) ───

def process_earnings_reminder(db: Session):
    """
    내일 실적발표 예정 종목 리마인더.
    사용자별 워치리스트/보유 종목 중 내일 어닝이 있는 종목 알림.
    Triggered at 20:30 UTC (거래일만).
    """
    today = date.today()
    if not _is_us_trading_day(today):
        logger.info(f"EARNINGS_REMINDER skipped: {today} is not a trading day")
        return

    tomorrow = _get_next_trading_date(today)

    if _already_notified(db, today, "ALL", "EARNINGS_REMINDER"):
        return

    # 사용자별 내일 어닝 종목 조회
    result = db.execute(text("""
        SELECT up.user_id, array_agg(DISTINCT up.ticker ORDER BY up.ticker)
        FROM analytics.user_portfolios up
        JOIN analytics.earnings_week_events ew
            ON ew.ticker = up.ticker AND ew.earnings_date = :tomorrow
        WHERE up.type IN ('HOLDING', 'WATCHLIST')
        GROUP BY up.user_id
    """), {"tomorrow": tomorrow})
    rows = result.fetchall()

    if not rows:
        logger.info(f"EARNINGS_REMINDER skipped: no users with earnings tomorrow ({tomorrow})")
        return

    user_ids = [r[0] for r in rows]
    user_tokens = _get_user_tokens_map(db, user_ids)

    user_notifications = []
    for user_id, tickers in rows:
        if user_id not in user_tokens:
            continue
        info = user_tokens[user_id]
        ticker_list = _format_ticker_list(tickers, max_display=5)
        user_notifications.append({
            "user_id": user_id,
            "tokens": info["tokens"],
            "language": info["language"],
            "msg_params": {"tickers": ticker_list, "count": str(len(tickers))},
            "ticker": "",
            "data": {"type": "EARNINGS_REMINDER", "tickers": ",".join(tickers[:10])},
        })

    sent = _send_personalized_per_user(db, user_notifications, "EARNINGS_REMINDER")
    _log_notification(db, today, "ALL", "EARNINGS_REMINDER",
                      recipients=sent, success=sent)
    logger.info(f"EARNINGS_REMINDER sent: {sent} users, tomorrow={tomorrow}")


def process_watchlist_movers(db: Session, today: date):
    """
    워치리스트 종목 중 |change_pct| >= 3% 종목 알림.
    Triggered at 21:00 UTC (거래일만).
    """
    trading_date = _get_last_trading_date(db, today)
    if not trading_date:
        logger.info(f"WATCHLIST_MOVERS skipped: no trading data found up to {today}")
        return

    if _already_notified(db, trading_date, "ALL", "WATCHLIST_MOVERS"):
        return

    # 사용자별 큰 변동 종목 조회
    result = db.execute(text("""
        SELECT up.user_id, up.ticker, tp.change_pct
        FROM analytics.user_portfolios up
        JOIN analytics.ticker_prices tp
            ON tp.ticker = up.ticker AND tp.date = :trading_date
        WHERE up.type IN ('HOLDING', 'WATCHLIST')
          AND ABS(tp.change_pct) >= 3.0
        ORDER BY up.user_id, ABS(tp.change_pct) DESC
    """), {"trading_date": trading_date})
    rows = result.fetchall()

    if not rows:
        logger.info(f"WATCHLIST_MOVERS skipped: no significant movers on {trading_date}")
        return

    # user_id별 종목 그룹핑
    user_tickers = {}
    for user_id, ticker, change_pct in rows:
        if user_id not in user_tickers:
            user_tickers[user_id] = []
        user_tickers[user_id].append(ticker)

    user_ids = list(user_tickers.keys())
    user_tokens = _get_user_tokens_map(db, user_ids)

    user_notifications = []
    for user_id, tickers in user_tickers.items():
        if user_id not in user_tokens:
            continue
        info = user_tokens[user_id]
        ticker_list = _format_ticker_list(tickers, max_display=3)
        user_notifications.append({
            "user_id": user_id,
            "tokens": info["tokens"],
            "language": info["language"],
            "msg_params": {"tickers": ticker_list, "count": str(len(tickers))},
            "ticker": "",
            "data": {"type": "WATCHLIST_MOVERS", "tickers": ",".join(tickers[:10]),
                     "date": str(trading_date)},
        })

    sent = _send_personalized_per_user(db, user_notifications, "WATCHLIST_MOVERS")
    _log_notification(db, trading_date, "ALL", "WATCHLIST_MOVERS",
                      recipients=sent, success=sent)
    logger.info(f"WATCHLIST_MOVERS sent: {sent} users, date={trading_date}")


def process_score_change_notification(db: Session, today: date,
                                       ticker: str, new_score: float,
                                       signal: str = None):
    """
    스코어 인제스트 중 전일 대비 |delta| >= 20 변화 알림.
    Rate limit 적용 (1시간 제한).
    """
    if new_score is None:
        return

    new_score_int = int(new_score)

    # 전일 스코어 조회
    result = db.execute(text("""
        SELECT score FROM analytics.ticker_scores
        WHERE ticker = :ticker AND date < :today
        ORDER BY date DESC LIMIT 1
    """), {"ticker": ticker, "today": today})
    row = result.fetchone()

    if not row or row[0] is None:
        return

    old_score_int = int(row[0])
    delta = abs(new_score_int - old_score_int)

    if delta < 20:
        return

    if _already_notified(db, today, ticker, "SCORE_CHANGE"):
        return

    # 해당 종목 구독자 조회
    sub_rows = _get_subscribed_tokens(db, ticker)
    if not sub_rows:
        return

    # user_id별 그룹핑
    user_info = {}
    for user_id, token, language in sub_rows:
        if user_id not in user_info:
            user_info[user_id] = {"tokens": [], "language": language}
        user_info[user_id]["tokens"].append(token)

    user_notifications = []
    for user_id, info in user_info.items():
        params = _get_score_change_params(
            info["language"], ticker, old_score_int, new_score_int,
        )
        user_notifications.append({
            "user_id": user_id,
            "tokens": info["tokens"],
            "language": info["language"],
            "msg_params": params,
            "ticker": ticker,
            "data": {
                "type": "SCORE_CHANGE", "ticker": ticker,
                "old_score": str(old_score_int), "new_score": str(new_score_int),
            },
        })

    sent = _send_personalized_per_user(
        db, user_notifications, "SCORE_CHANGE", skip_rate_limit=False,
    )
    _log_notification(db, today, ticker, "SCORE_CHANGE",
                      score=new_score, recipients=sent, success=sent)
    logger.info(f"SCORE_CHANGE sent: ticker={ticker}, {old_score_int}→{new_score_int}, {sent} users")


def process_portfolio_daily(db: Session, today: date):
    """
    일일 포트폴리오 P&L 리포트.
    사용자별 당일 day_pnl 데이터가 있으면 개인화 리포트 발송.
    Triggered at 21:15 UTC (거래일만).
    """
    trading_date = _get_last_trading_date(db, today)
    if not trading_date:
        logger.info(f"PORTFOLIO_DAILY skipped: no trading data found up to {today}")
        return

    if _already_notified(db, trading_date, "ALL", "PORTFOLIO_DAILY"):
        return

    # 당일 포트폴리오 서머리가 있는 사용자 조회
    result = db.execute(text("""
        SELECT ps.user_id, ps.day_pnl, ps.day_pnl_pct, ps.holdings_detail
        FROM analytics.portfolio_summary ps
        WHERE ps.date = :trading_date AND ps.day_pnl IS NOT NULL
    """), {"trading_date": trading_date})
    rows = result.fetchall()

    if not rows:
        logger.info(f"PORTFOLIO_DAILY skipped: no portfolio data for {trading_date}")
        return

    user_ids = [r[0] for r in rows]
    user_tokens = _get_user_tokens_map(db, user_ids)

    user_notifications = []
    for user_id, day_pnl, day_pnl_pct, holdings_detail in rows:
        if user_id not in user_tokens:
            continue
        info = user_tokens[user_id]

        best_ticker, best_pct, worst_ticker, worst_pct = _extract_best_worst(
            holdings_detail,
        )
        pnl_str = f"${day_pnl:+,.0f}" if day_pnl else "$0"
        pnl_pct_str = f"{day_pnl_pct:+.1f}" if day_pnl_pct else "0.0"

        user_notifications.append({
            "user_id": user_id,
            "tokens": info["tokens"],
            "language": info["language"],
            "msg_params": {
                "day_pnl": pnl_str,
                "day_pnl_pct": pnl_pct_str,
                "best_ticker": best_ticker,
                "best_pct": best_pct,
                "worst_ticker": worst_ticker,
                "worst_pct": worst_pct,
            },
            "ticker": "",
            "data": {"type": "PORTFOLIO_DAILY", "date": str(trading_date)},
        })

    sent = _send_personalized_per_user(db, user_notifications, "PORTFOLIO_DAILY")
    _log_notification(db, trading_date, "ALL", "PORTFOLIO_DAILY",
                      recipients=sent, success=sent)
    logger.info(f"PORTFOLIO_DAILY sent: {sent} users, date={trading_date}")

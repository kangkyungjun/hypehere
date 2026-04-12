"""
MarketLens Django FCM 유틸리티 (multi-language)
- 일반 알림 (1시간 제한): 시그널, 뉴스, 신규글, 인기글
- 댓글 알림 (즉시 발송): 글 작성자, 대화 참여자
- 지원 언어: en, ko, ja, es (default: en)
"""
import logging
from collections import defaultdict
from datetime import timedelta

import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
from django.utils import timezone

from .models import DeviceToken, NotificationSubscription, NotificationRateLimit, NotificationHistory

logger = logging.getLogger(__name__)

# ── 다국어 메시지 템플릿 ──────────────────────────────────────────
MESSAGES = {
    "NEW_POST": {
        "en": {"title": "[{ticker}] New Post", "body": "{title}"},
        "ko": {"title": "[{ticker}] 새 글", "body": "{title}"},
        "ja": {"title": "[{ticker}] 新しい投稿", "body": "{title}"},
        "es": {"title": "[{ticker}] Nueva publicación", "body": "{title}"},
    },
    "HOT_POST": {
        "en": {"title": "[{ticker}] Trending Post", "body": "'{title}' — {count} likes!"},
        "ko": {"title": "[{ticker}] 인기글", "body": "'{title}' — 좋아요 {count}개 돌파!"},
        "ja": {"title": "[{ticker}] 人気投稿", "body": "'{title}' — いいね{count}件突破！"},
        "es": {"title": "[{ticker}] Publicación popular", "body": "'{title}' — ¡{count} me gusta!"},
    },
    "COMMENT_ON_MY_POST": {
        "en": {"title": "[{ticker}] New comment on your post", "body": "{nickname}: {content}"},
        "ko": {"title": "[{ticker}] 내 글에 새 댓글", "body": "{nickname}: {content}"},
        "ja": {"title": "[{ticker}] あなたの投稿に新しいコメント", "body": "{nickname}: {content}"},
        "es": {"title": "[{ticker}] Nuevo comentario en tu publicación", "body": "{nickname}: {content}"},
    },
    "COMMENT_ON_THREAD": {
        "en": {"title": "[{ticker}] New comment in thread", "body": "{nickname}: {content}"},
        "ko": {"title": "[{ticker}] 참여 중인 대화에 새 댓글", "body": "{nickname}: {content}"},
        "ja": {"title": "[{ticker}] 参加中のスレッドに新しいコメント", "body": "{nickname}: {content}"},
        "es": {"title": "[{ticker}] Nuevo comentario en la conversación", "body": "{nickname}: {content}"},
    },
}

DEFAULT_LANG = "en"


def _get_msg(lang, key, **params):
    """언어별 메시지 (title, body) 반환. 미지원 언어는 영어 fallback."""
    templates = MESSAGES.get(key, {})
    t = templates.get(lang) or templates.get(DEFAULT_LANG, {})
    return t.get("title", "").format(**params), t.get("body", "").format(**params)


# ── Firebase 초기화 ───────────────────────────────────────────────
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


# ── Rate limiting ─────────────────────────────────────────────────
def can_send_general(user_id):
    """일반 알림(시그널/뉴스/커뮤니티) 발송 가능 여부 (1시간 제한)"""
    rate = NotificationRateLimit.objects.filter(user_id=user_id).first()
    if not rate or not rate.last_general_notified_at:
        return True
    return timezone.now() - rate.last_general_notified_at >= timedelta(hours=1)


def _update_rate_limit(user_id):
    """발송 후 rate limit 타임스탬프 갱신"""
    NotificationRateLimit.objects.update_or_create(
        user_id=user_id,
        defaults={'last_general_notified_at': timezone.now()},
    )


# ── FCM 전송 ─────────────────────────────────────────────────────
def _send_fcm(tokens, title, body, data=None):
    """
    firebase-admin send_each()로 배치 발송
    Returns: (success_count, failure_count, invalid_tokens)
    """
    if not tokens:
        return 0, 0, []

    _get_firebase_app()

    messages = []
    for token in tokens:
        msg = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
            token=token,
        )
        messages.append(msg)

    invalid_tokens = []
    success_count = 0
    failure_count = 0

    # 500개씩 배치 (FCM 제한)
    for i in range(0, len(messages), 500):
        batch = messages[i:i + 500]
        batch_tokens = tokens[i:i + 500]
        try:
            response = messaging.send_each(batch)
            for j, send_response in enumerate(response.responses):
                if send_response.success:
                    success_count += 1
                else:
                    failure_count += 1
                    exc = send_response.exception
                    if exc and hasattr(exc, 'code'):
                        error_code = exc.code
                        if error_code in ('NOT_FOUND', 'UNREGISTERED', 'INVALID_ARGUMENT'):
                            invalid_tokens.append(batch_tokens[j])
        except Exception as e:
            logger.error(f"FCM send_each error: {e}")
            failure_count += len(batch)

    # 만료 토큰 비활성화
    if invalid_tokens:
        _deactivate_invalid_tokens(invalid_tokens)

    return success_count, failure_count, invalid_tokens


def _deactivate_invalid_tokens(invalid_tokens):
    """만료/무효 토큰 비활성화"""
    if invalid_tokens:
        updated = DeviceToken.objects.filter(
            token__in=invalid_tokens
        ).update(is_active=False)
        logger.info(f"Deactivated {updated} invalid FCM tokens")


# ── 알림 히스토리 저장 ─────────────────────────────────────────────
def _save_notification_history(user_ids, title, body, notification_type, ticker='', post_id=None):
    """rate limit 무관하게 모든 대상 사용자에게 알림 히스토리 저장"""
    if not user_ids:
        return
    objs = [
        NotificationHistory(
            user_id=uid, title=title, body=body,
            notification_type=notification_type, ticker=ticker,
            post_id=post_id,
        )
        for uid in user_ids
    ]
    NotificationHistory.objects.bulk_create(objs, ignore_conflicts=True)
    logger.info(f"Notification history saved: {len(objs)} users, type={notification_type}")


# ── 다국어 발송 함수 ──────────────────────────────────────────────

def send_general_to_ticker_subscribers(ticker, msg_key, msg_params=None, data=None, exclude_user=None):
    """
    일반 알림: 종목 구독자에게 다국어 발송 (1시간 제한 적용)
    각 사용자 디바이스의 language 설정에 맞춰 발송
    """
    params = msg_params or {}
    subs = NotificationSubscription.objects.filter(
        ticker=ticker.upper(), is_active=True
    ).select_related('user')

    if exclude_user:
        subs = subs.exclude(user_id=exclude_user)

    # 히스토리 저장: rate limit 무관하게 모든 구독자에게 (언어별 title/body)
    sub_list = list(subs)
    # 사용자별 언어 → 언어별 그룹핑하여 각 언어로 히스토리 저장
    user_lang_map = {}
    for sub in sub_list:
        devices = DeviceToken.objects.filter(
            user_id=sub.user_id, is_active=True
        ).values_list('language', flat=True).first()
        user_lang_map[sub.user_id] = devices or DEFAULT_LANG
    lang_users = defaultdict(list)
    for uid, lang in user_lang_map.items():
        lang_users[lang].append(uid)
    _post_id = int(data['post_id']) if data and data.get('post_id') else None
    for lang, uids in lang_users.items():
        title, body = _get_msg(lang, msg_key, **params)
        _save_notification_history(uids, title, body, msg_key, ticker=ticker.upper(), post_id=_post_id)

    sent = 0
    for sub in sub_list:
        if not can_send_general(sub.user_id):
            continue

        # 토큰 + 언어 조회
        devices = list(
            DeviceToken.objects.filter(
                user_id=sub.user_id, is_active=True
            ).values_list('token', 'language')
        )
        if not devices:
            continue

        # 사용자당 1개 언어로 통일 (최신 토큰 기준, 중복 발송 방지)
        all_tokens = [token for token, _ in devices]
        lang = devices[-1][1] or DEFAULT_LANG
        title, body = _get_msg(lang, msg_key, **params)
        success, _, _ = _send_fcm(all_tokens, title, body, data)

        if success > 0:
            _update_rate_limit(sub.user_id)
            sent += 1

    logger.info(f"General notification [{ticker}]: sent to {sent} users")
    return sent


def send_general_to_all(msg_key, msg_params=None, data=None):
    """
    일반 알림: 전체 사용자에게 다국어 발송 (1시간 제한 적용)
    비로그인(user_id=NULL) 토큰도 포함, rate limit/history는 skip
    """
    params = msg_params or {}
    active_devices = DeviceToken.objects.filter(
        is_active=True
    ).values_list('user_id', 'token', 'language')

    # user별, 언어별 그룹핑 (user_id=None은 별도 처리)
    user_lang_tokens = defaultdict(lambda: defaultdict(list))
    anon_lang_tokens = defaultdict(list)  # 비로그인 토큰
    for user_id, token, lang in active_devices:
        if user_id is None:
            anon_lang_tokens[lang or DEFAULT_LANG].append(token)
        else:
            user_lang_tokens[user_id][lang or DEFAULT_LANG].append(token)

    # 히스토리 저장: 로그인 사용자만 (비로그인은 skip)
    lang_users = defaultdict(list)
    for user_id, lang_dict in user_lang_tokens.items():
        first_lang = next(iter(lang_dict.keys()), DEFAULT_LANG)
        lang_users[first_lang].append(user_id)
    for lang, uids in lang_users.items():
        title, body = _get_msg(lang, msg_key, **params)
        _save_notification_history(uids, title, body, msg_key)

    sent = 0

    # 로그인 사용자: 사용자당 1개 언어로 통일 발송 (중복 방지)
    for user_id, lang_dict in user_lang_tokens.items():
        if not can_send_general(user_id):
            continue

        all_tokens = []
        last_lang = DEFAULT_LANG
        for lang, tokens in lang_dict.items():
            all_tokens.extend(tokens)
            last_lang = lang
        title, body = _get_msg(last_lang, msg_key, **params)
        success, _, _ = _send_fcm(all_tokens, title, body, data)

        if success > 0:
            _update_rate_limit(user_id)
            sent += 1

    # 비로그인 토큰: rate limit/history 없이 바로 발송
    for lang, tokens in anon_lang_tokens.items():
        title, body = _get_msg(lang, msg_key, **params)
        success, _, _ = _send_fcm(tokens, title, body, data)
        if success > 0:
            sent += 1

    logger.info(f"General notification [ALL]: sent to {sent} users/devices")
    return sent


def send_comment_notification(user_id, msg_key, msg_params=None, data=None):
    """
    댓글 알림: 특정 사용자에게 다국어 즉시 발송 (제한 면제)
    """
    params = msg_params or {}
    devices = list(
        DeviceToken.objects.filter(
            user_id=user_id, is_active=True
        ).values_list('token', 'language')
    )

    # 히스토리 저장 (디바이스 없어도 기록)
    first_lang = DEFAULT_LANG
    if devices:
        first_lang = devices[0][1] or DEFAULT_LANG
    title_h, body_h = _get_msg(first_lang, msg_key, **params)
    ticker = params.get('ticker', '')
    _post_id = int(data['post_id']) if data and data.get('post_id') else None
    _save_notification_history([user_id], title_h, body_h, msg_key, ticker=ticker, post_id=_post_id)

    if not devices:
        return 0

    # 사용자당 1개 언어로 통일 (최신 토큰 기준, 중복 발송 방지)
    all_tokens = [token for token, _ in devices]
    lang = devices[-1][1] or DEFAULT_LANG
    title, body = _get_msg(lang, msg_key, **params)
    success, _, _ = _send_fcm(all_tokens, title, body, data)

    return success

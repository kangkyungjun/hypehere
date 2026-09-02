"""Ops alerts — 운영 이상(광고 로드 실패 등)을 owner/매니저에게 통지.

광고 로드 실패 시:
  - master/manager 역할 유저에게 FCM 푸시 알림
  - owner(master 역할 유저 + settings.ALERT_OWNER_EMAIL)에게 이메일

스팸 방지: settings.AD_FAILURE_ALERT_THROTTLE_SECONDS(기본 1800초=30분) 윈도 내
1회만 발송한다. 광고 로드 실패는 짧은 간격으로 반복 발생하므로 throttle 필수.
"""
import logging

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.core.mail import send_mail

from .models import DeviceToken
from .fcm_utils import _send_fcm

logger = logging.getLogger(__name__)

_AD_FAILURE_THROTTLE_KEY = 'ops:ad_failure_alert_sent'

# 알림에서 제외할 "광고 재고 없음" 코드 — **플랫폼마다 번호가 다르다.**
#
# google_mobile_ads 플러그인은 네이티브 코드를 정규화 없이 그대로 올린다
# (ios/Classes/FLTAd_Internal.m: `_code = error.code;`). 따라서 같은 숫자가
# 안드로이드와 iOS에서 전혀 다른 뜻이다:
#
#   코드 | Android (AdRequest.ERROR_CODE_*) | iOS (GADErrorCode)
#   -----+----------------------------------+--------------------
#     0  | INTERNAL_ERROR                   | InvalidRequest
#     1  | INVALID_REQUEST                  | **NoFill**
#     2  | NETWORK_ERROR                    | NetworkError
#     3  | **NO_FILL**                      | ServerError
#     9  | MEDIATION_NO_FILL                | MediationNoFill(deprecated)
#    20  | —                                | ApplicationIdentifierMissing
#
# 과거 이 필터는 {3}뿐이어서 **안드로이드 기준만** 맞았다. 그 결과:
#   · iOS의 정상적인 재고 없음(1)이 "INVALID_REQUEST"로 오인돼 알림 폭주
#   · iOS의 진짜 서버 오류(3)는 NO_FILL로 오인돼 조용히 누락
# 둘 다 이 표로 바로잡는다.
#
# 재고 없음은 신규 앱·소규모 트래픽에서 일상적으로 발생하며 운영자가 손쓸 것이
# 없다. 트래픽과 이력이 쌓이면 자연히 채워진다. 그래서 알림 대상이 아니다.
# 반면 설정 오류(iOS 20 / Android 8)·서버 오류·네트워크 오류는 그대로 알린다.
_IGNORED_CODES_BY_PLATFORM = {
    'android': {3, 9},   # NO_FILL, MEDIATION_NO_FILL
    'ios': {1, 9},       # NoFill, MediationNoFill
}

# platform이 비어 있는 구버전 클라이언트용 보조 판별.
_IOS_DOMAIN_HINT = 'admob'
_ANDROID_DOMAIN_HINT = 'android.gms.ads'


def _resolve_platform(platform, error_domain):
    """보고된 platform을 정규화한다. 없으면 error_domain으로 추정한다."""
    p = (platform or '').strip().lower()
    if p in _IGNORED_CODES_BY_PLATFORM:
        return p
    d = (error_domain or '').lower()
    if _ANDROID_DOMAIN_HINT in d:
        return 'android'
    if _IOS_DOMAIN_HINT in d:
        return 'ios'
    return ''


def _is_no_fill(error_code, platform, error_domain):
    """이 실패가 '광고 재고 없음'(정상)인지 판정한다."""
    if error_code is None:
        return False
    resolved = _resolve_platform(platform, error_domain)
    if resolved:
        return error_code in _IGNORED_CODES_BY_PLATFORM[resolved]
    # 플랫폼을 특정하지 못하면 양쪽 no-fill 코드의 합집합으로 보수적으로 판단한다.
    # 알림 폭주를 막는 쪽을 택하되, 아래에서 warning 로그를 남겨 추적 가능하게 한다.
    logger.warning(
        '[AdFailureAlert] platform 미상 (platform=%r domain=%r) — 합집합 필터 적용',
        platform, error_domain,
    )
    return error_code in {1, 3, 9}


def notify_ad_failure(
    *,
    error_message='',
    platform='',
    app_version='',
    ad_unit='',
    error_code=None,
    error_domain='',
):
    """광고 로드 실패 알림 발송 (throttle + NO_FILL 필터). 실제로 발송하면 True 반환."""

    # 재고 없음(no-fill)은 정상 동작이므로 알림 skip (서버 로그만 남김)
    if _is_no_fill(error_code, platform, error_domain):
        logger.info(
            '[AdFailureAlert] no-fill 무시 code=%s ad_unit=%s platform=%s',
            error_code, ad_unit, platform,
        )
        return False

    # NO_FILL은 위에서 이미 필터됨. 남은 에러(INTERNAL/INVALID_REQUEST/NETWORK 등)는
    # 즉시 인지가 필요하므로 throttle은 짧게 유지(기본 30분).
    throttle = getattr(settings, 'AD_FAILURE_ALERT_THROTTLE_SECONDS', 1800)

    # 스팸 방지: throttle 윈도 내 이미 보냈으면 skip
    if cache.get(_AD_FAILURE_THROTTLE_KEY):
        logger.info('[AdFailureAlert] throttled — skip')
        return False
    cache.set(_AD_FAILURE_THROTTLE_KEY, True, throttle)

    User = get_user_model()
    title = '⚠️ 광고 로드 실패 감지'
    code_label = f'code={error_code}' if error_code is not None else 'code=?'
    body = f'[{platform or "unknown"}/{ad_unit or "?"}/{code_label}] {error_message}'[:200]

    # 1) FCM 푸시 → master + manager
    try:
        tokens = list(
            DeviceToken.objects.filter(
                user__role__in=['master', 'manager'], is_active=True
            ).values_list('token', flat=True)
        )
        if tokens:
            _send_fcm(tokens, title, body, data={'type': 'ops_ad_failure'})
            logger.info(f'[AdFailureAlert] FCM sent to {len(tokens)} tokens')
    except Exception as e:  # noqa: BLE001
        logger.error(f'[AdFailureAlert] FCM failed: {e}')

    # 2) 이메일 → owner (master 역할 유저 + ALERT_OWNER_EMAIL)
    try:
        recipients = set(
            User.objects.filter(role='master').values_list('email', flat=True)
        )
        owner_email = getattr(settings, 'ALERT_OWNER_EMAIL', '') or ''
        if owner_email:
            recipients.add(owner_email)
        recipients = [e for e in recipients if e]
        if recipients:
            message = (
                '광고 로드 실패가 감지되었습니다.\n\n'
                f'· 플랫폼: {platform or "unknown"}\n'
                f'· 앱 버전: {app_version or "-"}\n'
                f'· 광고 유닛: {ad_unit or "-"}\n'
                f'· 에러 코드: {error_code if error_code is not None else "-"}\n'
                f'· 에러 도메인: {error_domain or "-"}\n'
                f'· 에러 메시지: {error_message or "-"}\n\n'
                f'(NO_FILL(code=3)은 자동 제외. '
                f'이 알림은 {throttle // 60}분에 1회만 발송됩니다.)'
            )
            send_mail(
                subject=title,
                message=message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=recipients,
                fail_silently=True,
            )
            logger.info(f'[AdFailureAlert] email sent to {recipients}')
    except Exception as e:  # noqa: BLE001
        logger.error(f'[AdFailureAlert] email failed: {e}')

    return True

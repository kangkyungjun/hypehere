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


def notify_ad_failure(*, error_message='', platform='', app_version='', ad_unit=''):
    """광고 로드 실패 알림 발송 (throttle 적용). 실제로 발송하면 True 반환."""
    throttle = getattr(settings, 'AD_FAILURE_ALERT_THROTTLE_SECONDS', 1800)

    # 스팸 방지: throttle 윈도 내 이미 보냈으면 skip
    if cache.get(_AD_FAILURE_THROTTLE_KEY):
        logger.info('[AdFailureAlert] throttled — skip')
        return False
    cache.set(_AD_FAILURE_THROTTLE_KEY, True, throttle)

    User = get_user_model()
    title = '⚠️ 광고 로드 실패 감지'
    body = f'[{platform or "unknown"}] {error_message}'[:200]

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
                f'· 에러: {error_message or "-"}\n\n'
                f'(스팸 방지를 위해 이 알림은 {throttle // 60}분에 1회만 발송됩니다.)'
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

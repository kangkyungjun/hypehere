import random
import logging
from datetime import timedelta

from django.conf import settings
from django.core.mail import send_mail
from django.utils import timezone

from .models import EmailVerificationCode

logger = logging.getLogger(__name__)


def create_and_send_code(email, purpose):
    """
    인증코드 생성 및 이메일 발송.
    Returns: (success: bool, error_message: str or None, cooldown_remaining: int or None)
    """
    now = timezone.now()
    cooldown_seconds = settings.VERIFICATION_CODE_RESEND_COOLDOWN_SECONDS

    # 60초 재전송 쿨다운 체크
    recent = EmailVerificationCode.objects.filter(
        email=email,
        purpose=purpose,
        created_at__gte=now - timedelta(seconds=cooldown_seconds),
    ).order_by('-created_at').first()

    if recent:
        elapsed = (now - recent.created_at).total_seconds()
        remaining = int(cooldown_seconds - elapsed)
        return False, 'cooldown', max(remaining, 1)

    # 기존 미사용 코드 무효화
    EmailVerificationCode.objects.filter(
        email=email,
        purpose=purpose,
        is_used=False,
    ).update(is_used=True)

    # 6자리 랜덤 숫자 생성
    code = f'{random.randint(0, 999999):06d}'
    expiry_minutes = settings.VERIFICATION_CODE_EXPIRY_MINUTES
    expires_at = now + timedelta(minutes=expiry_minutes)

    verification = EmailVerificationCode.objects.create(
        email=email,
        code=code,
        purpose=purpose,
        expires_at=expires_at,
    )

    # 이메일 발송
    if purpose == 'signup':
        subject = '[MarketLens] Email Verification Code'
        message = (
            f'Your MarketLens verification code is:\n\n'
            f'    {code}\n\n'
            f'This code expires in {expiry_minutes} minutes.\n'
            f'If you did not request this, please ignore this email.'
        )
    else:
        subject = '[MarketLens] Password Reset Code'
        message = (
            f'Your MarketLens password reset code is:\n\n'
            f'    {code}\n\n'
            f'This code expires in {expiry_minutes} minutes.\n'
            f'If you did not request this, please ignore this email.'
        )

    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
            fail_silently=False,
        )
    except Exception as e:
        logger.error(f'Failed to send verification email to {email}: {e}')
        verification.delete()
        return False, 'send_failed', None

    return True, None, None


SUBSCRIPTION_EMAIL_TEMPLATES = {
    "INITIAL_PURCHASE": {
        "en": {
            "subject": "[MarketLens] Gold Membership Activated",
            "body": (
                "Your MarketLens Gold membership is now active!\n\n"
                "You now have access to:\n"
                "  - Unlimited holdings\n"
                "  - Ad-free AI analysis\n"
                "  - Ad-free experience\n\n"
                "Important: Payment is processed through your device's {store} account.\n"
                "If you purchased on someone else's device, the device owner's account will be charged.\n\n"
                "Manage your subscription in {store} Settings > Subscriptions.\n\n"
                "Thank you for choosing MarketLens Gold!"
            ),
        },
        "ko": {
            "subject": "[MarketLens] Gold 멤버십이 활성화되었습니다",
            "body": (
                "MarketLens Gold 멤버십이 활성화되었습니다!\n\n"
                "이용 가능한 혜택:\n"
                "  - 무제한 보유종목\n"
                "  - 광고 없는 AI 분석\n"
                "  - 광고 없는 환경\n\n"
                "알림: 결제는 기기의 {store} 계정을 통해 처리됩니다.\n"
                "다른 사람의 기기에서 구매한 경우, 기기 소유자의 계정으로 청구됩니다.\n\n"
                "구독 관리: {store} 설정 > 구독에서 관리할 수 있습니다.\n\n"
                "MarketLens Gold를 선택해 주셔서 감사합니다!"
            ),
        },
        "ja": {
            "subject": "[MarketLens] Goldメンバーシップが有効になりました",
            "body": (
                "MarketLens Goldメンバーシップが有効になりました！\n\n"
                "ご利用いただける特典:\n"
                "  - 無制限の保有銘柄\n"
                "  - 広告なしAI分析\n"
                "  - 広告なし環境\n\n"
                "ご注意: お支払いは端末の{store}アカウントを通じて処理されます。\n"
                "他の方の端末で購入された場合、端末所有者のアカウントに請求されます。\n\n"
                "サブスクリプション管理: {store}設定 > サブスクリプションから管理できます。"
            ),
        },
        "zh": {
            "subject": "[MarketLens] Gold会员已激活",
            "body": (
                "MarketLens Gold会员已激活！\n\n"
                "可用权益:\n"
                "  - 无限持仓\n"
                "  - 无广告AI分析\n"
                "  - 无广告体验\n\n"
                "提示: 付款通过设备的{store}账户处理。\n"
                "如果您在他人设备上购买，费用将从设备所有者的账户中扣除。\n\n"
                "订阅管理: 在{store}设置 > 订阅中管理。"
            ),
        },
        "es": {
            "subject": "[MarketLens] Membresía Gold activada",
            "body": (
                "¡Tu membresía MarketLens Gold está activa!\n\n"
                "Beneficios disponibles:\n"
                "  - Posiciones ilimitadas\n"
                "  - Análisis AI sin anuncios\n"
                "  - Experiencia sin anuncios\n\n"
                "Importante: El pago se procesa a través de la cuenta de {store} del dispositivo.\n"
                "Si compraste en el dispositivo de otra persona, se cobrará a la cuenta del propietario.\n\n"
                "Gestiona tu suscripción en Ajustes de {store} > Suscripciones."
            ),
        },
    },
    "RENEWAL": {
        "en": {
            "subject": "[MarketLens] Gold Membership Renewed",
            "body": (
                "Your MarketLens Gold membership has been renewed.\n\n"
                "Next renewal date: {expiration_date}\n\n"
                "Manage your subscription in {store} Settings > Subscriptions."
            ),
        },
        "ko": {
            "subject": "[MarketLens] Gold 멤버십이 갱신되었습니다",
            "body": (
                "MarketLens Gold 멤버십이 갱신되었습니다.\n\n"
                "다음 갱신일: {expiration_date}\n\n"
                "구독 관리: {store} 설정 > 구독"
            ),
        },
        "ja": {
            "subject": "[MarketLens] Goldメンバーシップが更新されました",
            "body": (
                "MarketLens Goldメンバーシップが更新されました。\n\n"
                "次回更新日: {expiration_date}\n\n"
                "サブスクリプション管理: {store}設定 > サブスクリプション"
            ),
        },
        "zh": {
            "subject": "[MarketLens] Gold会员已续费",
            "body": (
                "MarketLens Gold会员已续费。\n\n"
                "下次续费日期: {expiration_date}\n\n"
                "订阅管理: {store}设置 > 订阅"
            ),
        },
        "es": {
            "subject": "[MarketLens] Membresía Gold renovada",
            "body": (
                "Tu membresía MarketLens Gold ha sido renovada.\n\n"
                "Próxima renovación: {expiration_date}\n\n"
                "Gestiona tu suscripción en Ajustes de {store} > Suscripciones."
            ),
        },
    },
    "EXPIRATION": {
        "en": {
            "subject": "[MarketLens] Gold Membership Expired",
            "body": (
                "Your MarketLens Gold membership has expired.\n\n"
                "You can resubscribe anytime from the app to continue enjoying Gold benefits.\n\n"
                "We hope to see you again!"
            ),
        },
        "ko": {
            "subject": "[MarketLens] Gold 멤버십이 만료되었습니다",
            "body": (
                "MarketLens Gold 멤버십이 만료되었습니다.\n\n"
                "앱에서 언제든 다시 구독하여 Gold 혜택을 이용할 수 있습니다.\n\n"
                "다시 만나길 기대합니다!"
            ),
        },
        "ja": {
            "subject": "[MarketLens] Goldメンバーシップが期限切れです",
            "body": (
                "MarketLens Goldメンバーシップが期限切れです。\n\n"
                "アプリからいつでも再購読してGold特典をお楽しみいただけます。\n\n"
                "またのご利用をお待ちしております！"
            ),
        },
        "zh": {
            "subject": "[MarketLens] Gold会员已过期",
            "body": (
                "MarketLens Gold会员已过期。\n\n"
                "您可以随时在应用中重新订阅以继续享受Gold权益。\n\n"
                "期待您的回归！"
            ),
        },
        "es": {
            "subject": "[MarketLens] Membresía Gold expirada",
            "body": (
                "Tu membresía MarketLens Gold ha expirado.\n\n"
                "Puedes volver a suscribirte en cualquier momento desde la app.\n\n"
                "¡Esperamos verte de nuevo!"
            ),
        },
    },
}


def send_subscription_email(user, event_type, context=None):
    """
    구독 이벤트 이메일 발송 (INITIAL_PURCHASE, RENEWAL, EXPIRATION)
    context: {'expiration_date': str, 'store': str}
    """
    templates = SUBSCRIPTION_EMAIL_TEMPLATES.get(event_type)
    if not templates:
        return

    ctx = context or {}

    # 사용자 언어 감지 (DeviceToken 기반)
    from .models import DeviceToken
    lang = 'en'
    device = DeviceToken.objects.filter(
        user_id=user.id, is_active=True
    ).values_list('language', flat=True).first()
    if device:
        lang = device

    t = templates.get(lang) or templates.get('en', {})
    subject = t.get('subject', '')
    body = t.get('body', '').format(**ctx)

    try:
        send_mail(
            subject=subject,
            message=body,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            fail_silently=False,
        )
        logger.info(f"Subscription email [{event_type}] sent to {user.email}")
    except Exception as e:
        logger.error(f"Failed to send subscription email [{event_type}] to {user.email}: {e}")


def verify_code(email, code, purpose):
    """
    인증코드 검증.
    Returns: (success: bool, error_type: str or None)
    error_type: 'not_found' | 'expired' | 'max_attempts' | 'invalid_code'
    """
    verification = EmailVerificationCode.objects.filter(
        email=email,
        purpose=purpose,
        is_used=False,
    ).order_by('-created_at').first()

    if not verification:
        return False, 'not_found'

    if verification.is_expired:
        return False, 'expired'

    max_attempts = settings.VERIFICATION_CODE_MAX_ATTEMPTS
    if verification.attempts >= max_attempts:
        return False, 'max_attempts'

    if verification.code != code:
        verification.attempts += 1
        verification.save(update_fields=['attempts'])
        if verification.attempts >= max_attempts:
            return False, 'max_attempts'
        return False, 'invalid_code'

    # 성공
    verification.is_used = True
    verification.save(update_fields=['is_used'])
    return True, None

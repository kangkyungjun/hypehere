"""
Admin actions for chat report moderation
"""
from django.utils import timezone
from django.utils.translation import gettext as _
from django.contrib.auth import get_user_model
from notifications.models import Notification

User = get_user_model()


def check_and_apply_auto_suspension(user, admin_user):
    """
    Check active report count and apply auto-suspension based on thresholds

    Thresholds:
    - 5 active reports = 3 days suspension
    - 10 active reports = 7 days suspension
    - 20 active reports = permanent ban
    """
    active_report_count = user.get_active_report_count()

    # Check if already banned
    if user.is_banned:
        return None

    # Check thresholds (highest first)
    if active_report_count >= 20:
        # Permanent ban
        user.ban_account(
            reason=f"활성 신고 누적 ({active_report_count}건)",
            admin_user=admin_user
        )

        # Send notification
        Notification.objects.create(
            recipient=user,
            sender=None,
            notification_type='REPORT',
            text_preview=_("활성 신고 %(count)s건 누적으로 계정이 영구 정지되었습니다") % {'count': active_report_count}
        )
        return 'banned'

    elif active_report_count >= 10:
        # 7 days suspension
        if not user.is_suspended or user.suspended_until:
            user.suspend_account(
                duration_days=7,
                reason=f"활성 신고 누적 ({active_report_count}건)",
                admin_user=admin_user
            )

            # Send notification
            Notification.objects.create(
                recipient=user,
                sender=None,
                notification_type='REPORT',
                text_preview=_("활성 신고 %(count)s건 누적으로 계정이 7일간 정지되었습니다") % {'count': active_report_count}
            )
            return 'suspended_7d'

    elif active_report_count >= 5:
        # 3 days suspension
        if not user.is_suspended or user.suspended_until:
            user.suspend_account(
                duration_days=3,
                reason=f"활성 신고 누적 ({active_report_count}건)",
                admin_user=admin_user
            )

            # Send notification
            Notification.objects.create(
                recipient=user,
                sender=None,
                notification_type='REPORT',
                text_preview=_("활성 신고 %(count)s건 누적으로 계정이 3일간 정지되었습니다") % {'count': active_report_count}
            )
            return 'suspended_3d'

    return None


def handle_chat_report_delete(report, admin_user):
    """
    Handle delete action on chat report (승인 처리)
    1. Update report status to resolved
    2. Increment user report count
    3. Check and apply auto-suspension
    4. Send notifications to reported user & reporter
    """
    reported_user = report.reported_user
    reporter = report.reporter
    conversation = report.conversation

    # 1. Update report status
    report.status = 'resolved'
    report.resolved_at = timezone.now()
    report.resolved_by = admin_user
    report.admin_note = f"신고 승인 처리됨 (관리자: {admin_user.nickname})"
    report.save()

    # 2. Increment user report count
    reported_user.increment_report_count()

    # 3. Check and apply auto-suspension
    suspension_result = check_and_apply_auto_suspension(reported_user, admin_user)

    # 4. Send notification to reported user
    if suspension_result:
        # Notification already sent by auto-suspension
        pass
    else:
        Notification.objects.create(
            recipient=reported_user,
            sender=None,
            notification_type='REPORT',
            content_object=report,
            text_preview=_("채팅 신고가 승인되었습니다. 주의해 주세요.")
        )

    # 5. Send notification to reporter
    Notification.objects.create(
        recipient=reporter,
        sender=None,
        notification_type='REPORT',
        content_object=report,
        text_preview=_("신고하신 채팅 내용이 검토되어 조치가 완료되었습니다.")
    )

    return {
        'success': True,
        'message': '채팅 신고가 승인 처리되었습니다.',
        'suspension_result': suspension_result,
        'report_count': reported_user.report_count,
        'active_report_count': reported_user.get_active_report_count()
    }


def handle_chat_report_dismiss(report, admin_user):
    """
    Handle dismiss action on chat report (기각 처리)
    1. Update report status to dismissed
    2. Decrement user report count (if already incremented)
    3. Send notification to reporter
    """
    reported_user = report.reported_user
    reporter = report.reporter

    # 1. Update report status
    old_status = report.status
    report.status = 'dismissed'
    report.resolved_at = timezone.now()
    report.resolved_by = admin_user
    report.admin_note = f"신고 기각 처리됨 (관리자: {admin_user.nickname})"
    report.save()

    # 2. Decrement user report count if report was resolved
    if old_status == 'resolved':
        reported_user.decrement_report_count()

    # 3. Send notification to reporter
    Notification.objects.create(
        recipient=reporter,
        sender=None,
        notification_type='REPORT',
        content_object=report,
        text_preview=_("신고하신 채팅 내용이 검토되었으나 기각되었습니다.")
    )

    return {
        'success': True,
        'message': '채팅 신고가 기각 처리되었습니다.',
        'report_count': reported_user.report_count,
        'active_report_count': reported_user.get_active_report_count()
    }

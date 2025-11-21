"""
Admin actions for post report moderation
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


def handle_report_delete(report, admin_user):
    """
    Handle delete action on report
    1. Soft delete post
    2. Update report status
    3. Increment user report count
    4. Send notifications to author & reporter
    """
    post = report.post
    author = report.reported_user
    reporter = report.reporter

    # 1. Soft delete post
    if post and not post.is_deleted_by_report:
        post.delete_by_report(
            report_type=report.report_type,
            admin_user=admin_user
        )

    # 2. Update report status
    report.status = 'resolved'
    report.reviewed_at = timezone.now()
    report.resolved_by = admin_user
    report.admin_note = f"Post deleted by {admin_user.nickname}"
    report.save(update_fields=[
        'status', 'reviewed_at', 'resolved_by', 'admin_note'
    ])

    # 3. Increment author's report count
    author.increment_report_count()

    # 3.5. Check for auto-suspension based on active reports
    check_and_apply_auto_suspension(author, admin_user)

    # 4. Send notifications
    # To author
    Notification.objects.create(
        recipient=author,
        sender=None,  # System notification
        notification_type='REPORT',
        content_object=report,
        text_preview=_("신고로 인해 게시물이 삭제되었습니다 (%s)") % report.get_report_type_display()
    )

    # To reporter
    Notification.objects.create(
        recipient=reporter,
        sender=None,
        notification_type='REPORT',
        content_object=report,
        text_preview=_("신고하신 게시물이 처리되었습니다 (%s)") % report.get_report_type_display()
    )

    return True


def handle_report_dismiss(report, admin_user):
    """
    Handle dismiss action on report
    1. Update report status
    2. Decrement report count if previously counted
    3. Send notifications to author & reporter
    """
    author = report.reported_user
    reporter = report.reporter

    # Save old status for comparison
    old_status = report.status

    # 1. Update report status
    report.status = 'dismissed'
    report.reviewed_at = timezone.now()
    report.resolved_by = admin_user
    report.admin_note = f"Dismissed by {admin_user.nickname}"
    report.save(update_fields=[
        'status', 'reviewed_at', 'resolved_by', 'admin_note'
    ])

    # 2. Decrement report count if it was previously counted
    if old_status in ('resolved', 'reviewing'):
        author.decrement_report_count()

    # 3. Send notifications
    # To author (cleared notification)
    Notification.objects.create(
        recipient=author,
        sender=None,
        notification_type='REPORT',
        content_object=report,
        text_preview=_("신고가 검토되었으며 문제가 없다고 판단되었습니다")
    )

    # To reporter (dismissed notification)
    Notification.objects.create(
        recipient=reporter,
        sender=None,
        notification_type='REPORT',
        content_object=report,
        text_preview=_("신고하신 내용이 검토되었으나 조치가 필요하지 않다고 판단되었습니다")
    )

    return True


def handle_comment_report_delete(comment_report, admin_user):
    """
    Handle delete action on comment report
    1. Soft delete comment
    2. Update report status
    3. Increment user report count
    4. Send notifications to author & reporter
    """
    comment = comment_report.comment
    author = comment_report.reported_user
    reporter = comment_report.reporter

    # 1. Soft delete comment
    if comment and not comment.is_deleted_by_report:
        comment.delete_by_report(
            reason=_("신고로 인해 삭제됨 (%s)") % comment_report.get_report_type_display()
        )

    # 2. Update report status
    comment_report.status = 'resolved'
    comment_report.reviewed_at = timezone.now()
    comment_report.resolved_by = admin_user
    comment_report.admin_note = f"Comment deleted by {admin_user.nickname}"
    comment_report.save(update_fields=[
        'status', 'reviewed_at', 'resolved_by', 'admin_note'
    ])

    # 3. Increment author's report count
    author.increment_report_count()

    # 3.5. Check for auto-suspension based on active reports
    check_and_apply_auto_suspension(author, admin_user)

    # 4. Send notifications
    # To author
    Notification.objects.create(
        recipient=author,
        sender=None,  # System notification
        notification_type='REPORT',
        content_object=comment_report,
        text_preview=_("신고로 인해 댓글이 삭제되었습니다 (%s)") % comment_report.get_report_type_display()
    )

    # To reporter
    Notification.objects.create(
        recipient=reporter,
        sender=None,
        notification_type='REPORT',
        content_object=comment_report,
        text_preview=_("신고하신 댓글이 처리되었습니다 (%s)") % comment_report.get_report_type_display()
    )

    return True


def handle_comment_report_dismiss(comment_report, admin_user):
    """
    Handle dismiss action on comment report
    1. Update report status
    2. Decrement report count if previously counted
    3. Send notifications to author & reporter
    """
    author = comment_report.reported_user
    reporter = comment_report.reporter

    # Save old status for comparison
    old_status = comment_report.status

    # 1. Update report status
    comment_report.status = 'dismissed'
    comment_report.reviewed_at = timezone.now()
    comment_report.resolved_by = admin_user
    comment_report.admin_note = f"Dismissed by {admin_user.nickname}"
    comment_report.save(update_fields=[
        'status', 'reviewed_at', 'resolved_by', 'admin_note'
    ])

    # 2. Decrement report count if it was previously counted
    if old_status in ('resolved', 'reviewing'):
        author.decrement_report_count()

    # 3. Send notifications
    # To author (cleared notification)
    Notification.objects.create(
        recipient=author,
        sender=None,
        notification_type='REPORT',
        content_object=comment_report,
        text_preview=_("댓글 신고가 검토되었으며 문제가 없다고 판단되었습니다")
    )

    # To reporter (dismissed notification)
    Notification.objects.create(
        recipient=reporter,
        sender=None,
        notification_type='REPORT',
        content_object=comment_report,
        text_preview=_("신고하신 댓글이 검토되었으나 조치가 필요하지 않다고 판단되었습니다")
    )

    return True

import logging
from django.db.models.signals import post_save
from django.dispatch import receiver
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from django.conf import settings
from chat.models import Message
from accounts.models import Follow
from posts.models import Post, Comment, Like, PostReport, CommentReport
from .models import Notification, NotificationSettings

logger = logging.getLogger(__name__)


@receiver(post_save, sender=Message)
def create_message_notification(sender, instance, created, **kwargs):
    """
    새 메시지 전송 시 알림 생성

    Args:
        sender: Message 모델 (시그널 발신자)
        instance: 생성된 Message 객체
        created: 새로 생성되었는지 여부
        **kwargs: 추가 인자
    """
    if created:
        # 익명 채팅(랜덤 매칭)은 알림 생성 제외
        if instance.conversation.is_anonymous:
            logger.debug(f"익명 채팅 메시지는 알림 생성 안 함: conversation_id={instance.conversation.id}")
            return

        # 수신자 (대화의 상대방) 가져오기
        recipient = instance.conversation.get_other_user(instance.sender)

        if recipient:
            # 수신자가 현재 채팅방에 WebSocket 접속 중인지 확인
            # is_active=True인 경우, 실시간으로 메시지를 받고 있으므로 알림 제외
            try:
                from chat.models import ConversationParticipant
                participant = ConversationParticipant.objects.filter(
                    conversation=instance.conversation,
                    user=recipient
                ).first()

                if participant and participant.is_active:
                    logger.debug(f"수신자가 채팅방에 접속 중: {recipient.nickname} (conversation_id={instance.conversation.id})")
                    return
            except Exception as e:
                logger.error(f"ConversationParticipant 확인 중 오류: {e}")
                # 오류 발생 시에도 알림은 생성 (안전한 fallback)
                pass
            # 알림 설정 확인
            settings = NotificationSettings.objects.filter(user=recipient).first()
            if settings and settings.is_notification_enabled('MESSAGE'):
                # 알림 생성
                notification = Notification.create_message_notification(
                    recipient=recipient,
                    sender=instance.sender,
                    conversation=instance.conversation
                )

                logger.info(f"메시지 알림 생성: {instance.sender.nickname} → {recipient.nickname}")

                # WebSocket으로 실시간 알림 전송
                send_notification_via_websocket(notification)
            else:
                logger.debug(f"메시지 알림 비활성화: {recipient.nickname}")


@receiver(post_save, sender=Notification)
def send_notification_on_create(sender, instance, created, **kwargs):
    """
    Notification 생성 시 WebSocket으로 실시간 알림 전송

    Args:
        sender: Notification 모델 (시그널 발신자)
        instance: 생성된 Notification 객체
        created: 새로 생성되었는지 여부
        **kwargs: 추가 인자
    """
    if created and instance.notification_type != 'MESSAGE':
        # MESSAGE 타입은 create_message_notification에서 이미 처리됨
        logger.info(f"일반 알림 생성: {instance.notification_type} → {instance.recipient.nickname}")
        send_notification_via_websocket(instance)


def send_notification_via_websocket(notification):
    """
    WebSocket을 통해 알림을 수신자에게 전송

    Args:
        notification: Notification 객체
    """
    channel_layer = get_channel_layer()
    notification_group_name = f'user_notifications_{notification.recipient.id}'

    logger.debug(f"📤 WebSocket 전송: {notification_group_name}")

    # WebSocket으로 알림 전송
    async_to_sync(channel_layer.group_send)(
        notification_group_name,
        {
            'type': 'notification_update',
            'notification_id': notification.id,
            'notification_type': notification.notification_type,
            'message': notification.text_preview or '새로운 알림이 있습니다',
        }
    )

    logger.debug("✅ WebSocket 전송 완료")


# ============================================
# Phase 2: 소셜 알림 Signal 핸들러
# ============================================

@receiver(post_save, sender=Follow)
def create_follow_notification(sender, instance, created, **kwargs):
    """
    새 팔로워 알림 생성

    Args:
        sender: Follow 모델 (시그널 발신자)
        instance: 생성된 Follow 객체
        created: 새로 생성되었는지 여부
        **kwargs: 추가 인자
    """
    if created:
        # 알림 설정 확인
        recipient = instance.following  # 팔로우 받은 사람
        settings = NotificationSettings.objects.filter(user=recipient).first()
        if settings and settings.is_notification_enabled('FOLLOW'):
            # 팔로우 받은 사람에게 알림
            notification = Notification.create_follow_notification(
                recipient=recipient,
                sender=instance.follower       # 팔로우한 사람
            )

            logger.info(f"팔로우 알림 생성: {instance.follower.nickname} → {recipient.nickname}")

            # WebSocket으로 실시간 알림 전송
            send_notification_via_websocket(notification)
        else:
            logger.debug(f"팔로우 알림 비활성화: {recipient.nickname}")


@receiver(post_save, sender=Post)
def create_post_notification(sender, instance, created, **kwargs):
    """
    팔로워들에게 새 게시글 알림 생성 (bulk_create 최적화)

    Args:
        sender: Post 모델 (시그널 발신자)
        instance: 생성된 Post 객체
        created: 새로 생성되었는지 여부
        **kwargs: 추가 인자
    """
    if created:
        from django.contrib.contenttypes.models import ContentType

        # 작성자의 모든 팔로워 가져오기
        followers = instance.author.followers.all()
        follower_count = followers.count()

        logger.info(f"게시글 알림 생성: {instance.author.nickname} → 팔로워 {follower_count}명")

        # 팔로워가 없으면 종료
        if follower_count == 0:
            return

        # ContentType 사전 조회 (N+1 쿼리 방지)
        post_content_type = ContentType.objects.get_for_model(Post)

        # 알림 객체 리스트 생성 (설정 확인)
        notifications_to_create = []
        for follow in followers:
            recipient = follow.follower
            settings = NotificationSettings.objects.filter(user=recipient).first()
            if settings and settings.is_notification_enabled('POST'):
                notifications_to_create.append(
                    Notification(
                        recipient=recipient,
                        sender=instance.author,
                        notification_type='POST',
                        content_type=post_content_type,
                        object_id=instance.id,
                        text_preview=instance.content[:200] if instance.content else ''
                    )
                )

        # bulk_create로 배치 INSERT (성능 최적화)
        created_notifications = Notification.objects.bulk_create(
            notifications_to_create,
            batch_size=500
        )

        logger.info(f"bulk_create 완료: {len(created_notifications)}개 알림 생성")

        # 각 알림에 대해 WebSocket 전송
        for notification in created_notifications:
            send_notification_via_websocket(notification)


@receiver(post_save, sender=Comment)
def create_comment_notification(sender, instance, created, **kwargs):
    """
    댓글 작성 시 게시글 작성자에게 알림

    Args:
        sender: Comment 모델 (시그널 발신자)
        instance: 생성된 Comment 객체
        created: 새로 생성되었는지 여부
        **kwargs: 추가 인자
    """
    if created:
        # 자신의 게시글에 자신이 댓글 단 경우 제외
        if instance.author != instance.post.author:
            recipient = instance.post.author
            settings = NotificationSettings.objects.filter(user=recipient).first()
            if settings and settings.is_notification_enabled('COMMENT'):
                notification = Notification.create_comment_notification(
                    recipient=recipient,  # 게시글 작성자
                    sender=instance.author,          # 댓글 작성자
                    comment=instance                 # 댓글 객체
                )

                logger.info(f"댓글 알림 생성: {instance.author.nickname} → {recipient.nickname}")

                # WebSocket으로 실시간 알림 전송
                send_notification_via_websocket(notification)
            else:
                logger.debug(f"댓글 알림 비활성화: {recipient.nickname}")


@receiver(post_save, sender=Like)
def create_like_notification(sender, instance, created, **kwargs):
    """
    좋아요 시 게시글 작성자에게 알림

    Args:
        sender: Like 모델 (시그널 발신자)
        instance: 생성된 Like 객체
        created: 새로 생성되었는지 여부
        **kwargs: 추가 인자
    """
    if created:
        # 자신의 게시글에 자신이 좋아요 누른 경우 제외
        if instance.user != instance.post.author:
            recipient = instance.post.author
            settings = NotificationSettings.objects.filter(user=recipient).first()
            if settings and settings.is_notification_enabled('LIKE'):
                notification = Notification.create_like_notification(
                    recipient=recipient,  # 게시글 작성자
                    sender=instance.user,            # 좋아요 누른 사람
                    like=instance                    # 좋아요 객체
                )

                logger.info(f"좋아요 알림 생성: {instance.user.nickname} → {recipient.nickname}")

                # WebSocket으로 실시간 알림 전송
                send_notification_via_websocket(notification)
            else:
                logger.debug(f"좋아요 알림 비활성화: {recipient.nickname}")


@receiver(post_save, sender=PostReport)
def create_report_notification(sender, instance, created, **kwargs):
    """
    게시물 신고 시 모든 관리자에게 알림

    Args:
        sender: PostReport 모델 (시그널 발신자)
        instance: 생성된 PostReport 객체
        created: 새로 생성되었는지 여부
        **kwargs: 추가 인자
    """
    if created:
        from django.contrib.auth import get_user_model
        User = get_user_model()

        # 모든 관리자 (is_staff=True) 가져오기
        staff_users = User.objects.filter(is_staff=True)
        staff_count = staff_users.count()

        logger.info(f"신고 알림 생성: {instance.reporter.nickname} → 관리자 {staff_count}명")

        if staff_count == 0:
            logger.warning("경고: 관리자 계정이 없습니다")
            return

        # 각 관리자에게 알림 생성
        for staff_user in staff_users:
            notification = Notification.create_report_notification(
                recipient=staff_user,
                sender=instance.reporter,
                report=instance
            )

            logger.info(f"신고 알림 생성 완료: → {staff_user.nickname}")

            # WebSocket으로 실시간 알림 전송
            send_notification_via_websocket(notification)


@receiver(post_save, sender=CommentReport)
def create_comment_report_notification(sender, instance, created, **kwargs):
    """
    댓글 신고 시 모든 관리자에게 알림

    Args:
        sender: CommentReport 모델 (시그널 발신자)
        instance: 생성된 CommentReport 객체
        created: 새로 생성되었는지 여부
        **kwargs: 추가 인자
    """
    if created:
        from django.contrib.auth import get_user_model
        User = get_user_model()

        # 모든 관리자 (is_staff=True) 가져오기
        staff_users = User.objects.filter(is_staff=True)
        staff_count = staff_users.count()

        logger.info(f"댓글 신고 알림 생성: {instance.reporter.nickname} → 관리자 {staff_count}명")

        if staff_count == 0:
            logger.warning("경고: 관리자 계정이 없습니다")
            return

        # 각 관리자에게 알림 생성
        for staff_user in staff_users:
            notification = Notification.create_report_notification(
                recipient=staff_user,
                sender=instance.reporter,
                report=instance
            )

            logger.info(f"댓글 신고 알림 생성 완료: → {staff_user.nickname}")

            # WebSocket으로 실시간 알림 전송
            send_notification_via_websocket(notification)


# ============================================
# 알림 설정: 신규 유저 기본 설정 생성
# ============================================

@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_notification_settings(sender, instance, created, **kwargs):
    """
    신규 유저 생성 시 기본 알림 설정 생성

    Args:
        sender: User 모델 (시그널 발신자)
        instance: 생성된 User 객체
        created: 새로 생성되었는지 여부
        **kwargs: 추가 인자
    """
    if created:
        NotificationSettings.objects.create(user=instance)
        logger.info(f"기본 알림 설정 생성: {instance.nickname}")

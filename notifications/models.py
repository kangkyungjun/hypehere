from django.db import models
from django.conf import settings
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType


class Notification(models.Model):
    """
    다형성 알림 모델 - 여러 타입의 알림 지원
    Django ContentTypes를 사용하여 유연한 컨텐츠 참조
    """

    NOTIFICATION_TYPES = [
        ('MESSAGE', '새 메시지'),           # Phase 1
        ('FOLLOW', '새 팔로워'),            # Phase 2
        ('POST', '팔로우한 유저의 새 게시글'),   # Phase 2
        ('COMMENT', '게시글에 댓글'),        # Phase 2
        ('LIKE', '게시글에 좋아요'),         # Phase 2
        ('REPORT', '신고 접수'),            # Admin notification
    ]

    # 핵심 필드
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notifications',
        db_index=True,
        verbose_name='수신자'
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sent_notifications',
        null=True,
        blank=True,
        verbose_name='발신자'
    )
    notification_type = models.CharField(
        max_length=20,
        choices=NOTIFICATION_TYPES,
        db_index=True,
        verbose_name='알림 타입'
    )

    # 다형성 컨텐츠 참조 (Message, Post, Comment, Like 등)
    content_type = models.ForeignKey(
        ContentType,
        on_delete=models.CASCADE,
        null=True,
        blank=True
    )
    object_id = models.PositiveIntegerField(null=True, blank=True)
    content_object = GenericForeignKey('content_type', 'object_id')

    # 선택적 텍스트 미리보기 (메시지/게시글 내용)
    text_preview = models.CharField(max_length=200, blank=True, verbose_name='미리보기')

    # 상태 추적
    is_read = models.BooleanField(default=False, db_index=True, verbose_name='읽음 여부')
    created_at = models.DateTimeField(auto_now_add=True, db_index=True, verbose_name='생성 시간')

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['recipient', '-created_at']),
            models.Index(fields=['recipient', 'is_read', '-created_at']),
            models.Index(fields=['notification_type', '-created_at']),
        ]
        verbose_name = '알림'
        verbose_name_plural = '알림들'

    def __str__(self):
        return f"{self.get_notification_type_display()} - {self.recipient.nickname}"

    def mark_as_read(self):
        """알림을 읽음 상태로 표시"""
        if not self.is_read:
            self.is_read = True
            self.save(update_fields=['is_read'])

    @classmethod
    def create_message_notification(cls, recipient, sender, conversation):
        """
        새 메시지 알림 생성

        Args:
            recipient: 알림 받을 사용자
            sender: 메시지 보낸 사용자
            conversation: 대화 객체

        Returns:
            생성된 Notification 객체
        """
        # 마지막 메시지 가져오기
        last_message = conversation.messages.order_by('-created_at').first()

        return cls.objects.create(
            recipient=recipient,
            sender=sender,
            notification_type='MESSAGE',
            content_object=conversation,
            text_preview=last_message.content[:200] if last_message else ""
        )

    @classmethod
    def create_follow_notification(cls, recipient, sender):
        """
        새 팔로워 알림 생성 (Phase 2)

        Args:
            recipient: 팔로우 받은 사용자
            sender: 팔로우한 사용자

        Returns:
            생성된 Notification 객체
        """
        return cls.objects.create(
            recipient=recipient,
            sender=sender,
            notification_type='FOLLOW'
        )

    @classmethod
    def create_post_notification(cls, recipient, sender, post):
        """
        팔로우한 사용자의 새 게시글 알림 생성 (Phase 2)

        Args:
            recipient: 알림 받을 팔로워
            sender: 게시글 작성자
            post: 게시글 객체

        Returns:
            생성된 Notification 객체
        """
        return cls.objects.create(
            recipient=recipient,
            sender=sender,
            notification_type='POST',
            content_object=post,
            text_preview=post.content[:200]
        )

    @classmethod
    def create_comment_notification(cls, recipient, sender, comment):
        """
        게시글에 댓글 알림 생성 (Phase 2)

        Args:
            recipient: 게시글 작성자
            sender: 댓글 작성자
            comment: 댓글 객체

        Returns:
            생성된 Notification 객체
        """
        return cls.objects.create(
            recipient=recipient,
            sender=sender,
            notification_type='COMMENT',
            content_object=comment,
            text_preview=comment.content[:200]
        )

    @classmethod
    def create_like_notification(cls, recipient, sender, like):
        """
        게시글에 좋아요 알림 생성 (Phase 2)

        Args:
            recipient: 게시글 작성자
            sender: 좋아요 누른 사용자
            like: 좋아요 객체

        Returns:
            생성된 Notification 객체
        """
        return cls.objects.create(
            recipient=recipient,
            sender=sender,
            notification_type='LIKE',
            content_object=like
        )

    @classmethod
    def create_report_notification(cls, recipient, sender, report):
        """
        신고 접수 알림 생성 (Admin notification)

        Args:
            recipient: 알림 받을 관리자
            sender: 신고한 사용자
            report: 신고 객체 (PostReport 또는 CommentReport)

        Returns:
            생성된 Notification 객체
        """
        # Get preview text based on report type
        text_preview = ""
        if hasattr(report, 'post') and report.post:
            # PostReport
            text_preview = f"{report.get_report_type_display()}: {report.post.content[:100]}"
        elif hasattr(report, 'comment') and report.comment:
            # CommentReport
            text_preview = f"{report.get_report_type_display()}: {report.comment.content[:100]}"

        return cls.objects.create(
            recipient=recipient,
            sender=sender,
            notification_type='REPORT',
            content_object=report,
            text_preview=text_preview
        )


class NotificationSettings(models.Model):
    """사용자별 알림 설정"""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notification_settings',
        primary_key=True,
        verbose_name='사용자'
    )

    # 개별 알림 타입 토글
    enable_message_notifications = models.BooleanField(
        default=True,
        verbose_name='메시지 알림'
    )
    enable_follow_notifications = models.BooleanField(
        default=True,
        verbose_name='팔로우 알림'
    )
    enable_post_notifications = models.BooleanField(
        default=True,
        verbose_name='게시글 알림'
    )
    enable_comment_notifications = models.BooleanField(
        default=True,
        verbose_name='댓글 알림'
    )
    enable_like_notifications = models.BooleanField(
        default=True,
        verbose_name='좋아요 알림'
    )

    # 마스터 토글
    enable_all_notifications = models.BooleanField(
        default=True,
        verbose_name='모든 알림'
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Notification Settings'
        verbose_name_plural = 'Notification Settings'

    def __str__(self):
        return f"{self.user.nickname}'s notification settings"

    def is_notification_enabled(self, notification_type):
        """특정 알림 타입이 활성화되어 있는지 확인"""
        if not self.enable_all_notifications:
            return False

        type_map = {
            'MESSAGE': self.enable_message_notifications,
            'FOLLOW': self.enable_follow_notifications,
            'POST': self.enable_post_notifications,
            'COMMENT': self.enable_comment_notifications,
            'LIKE': self.enable_like_notifications,
        }
        return type_map.get(notification_type, False)

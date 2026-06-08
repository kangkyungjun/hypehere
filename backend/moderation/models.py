from django.db import models
from django.conf import settings


class BlockedUser(models.Model):
    """
    사용자 차단 모델 (Apple Guideline 1.2 (d) 대응)
    - blocker가 blocked를 차단하면, blocked의 게시글/댓글이 blocker의 피드에서 즉시 제거됨
    - 차단 시 관리자가 검토할 수 있도록 사유/연관 콘텐츠를 기록 (개발자 통보)
    """
    blocker = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='blocking',
        help_text="차단을 행한 사용자",
    )
    blocked = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='blocked_by',
        help_text="차단당한 사용자",
    )
    # 차단 시점에 신고된 콘텐츠 컨텍스트 (개발자 통보/검토용)
    context_post = models.ForeignKey(
        'community.Post',
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='+',
    )
    context_comment = models.ForeignKey(
        'community.Comment',
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='+',
    )
    reason = models.CharField(max_length=200, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = 'moderation_blocked_user'
        verbose_name = '사용자 차단'
        verbose_name_plural = '사용자 차단'
        ordering = ['-created_at']
        # 동일 사용자를 중복 차단할 수 없음
        unique_together = ['blocker', 'blocked']
        indexes = [
            models.Index(fields=['blocker']),
            models.Index(fields=['blocked']),
        ]

    def __str__(self):
        return f"{self.blocker_id} ⊘ {self.blocked_id}"


class PostReport(models.Model):
    """
    게시글 신고 모델 (미래 확장용 스켈레톤)
    - 관리자 검토 및 조치 관리
    """
    REASON_CHOICES = [
        ('spam', '스팸'),
        ('abuse', '욕설/비방'),
        ('false_info', '허위 정보'),
        ('inappropriate', '부적절한 내용'),
        ('other', '기타'),
    ]

    STATUS_CHOICES = [
        ('pending', '대기중'),
        ('reviewing', '검토중'),
        ('resolved', '처리완료'),
        ('dismissed', '기각'),
    ]

    post = models.ForeignKey(
        'community.Post',
        on_delete=models.CASCADE,
        related_name='reports'
    )
    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='post_reports'
    )
    reason = models.CharField(max_length=20, choices=REASON_CHOICES)
    description = models.TextField(max_length=500, blank=True)

    # 관리자 처리 정보
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    admin_note = models.TextField(max_length=500, blank=True)

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'post_reports'
        verbose_name = '게시글 신고'
        verbose_name_plural = '게시글 신고'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', '-created_at']),
            models.Index(fields=['post']),
        ]
        # 동일 사용자가 동일 게시글을 중복 신고할 수 없음
        unique_together = ['post', 'reporter']

    def __str__(self):
        return f"{self.reporter.nickname} → {self.post.title} ({self.get_reason_display()})"


class CommentReport(models.Model):
    """
    댓글 신고 모델 (미래 확장용 스켈레톤)
    - 관리자 검토 및 조치 관리
    """
    REASON_CHOICES = [
        ('spam', '스팸'),
        ('abuse', '욕설/비방'),
        ('false_info', '허위 정보'),
        ('inappropriate', '부적절한 내용'),
        ('other', '기타'),
    ]

    STATUS_CHOICES = [
        ('pending', '대기중'),
        ('reviewing', '검토중'),
        ('resolved', '처리완료'),
        ('dismissed', '기각'),
    ]

    comment = models.ForeignKey(
        'community.Comment',
        on_delete=models.CASCADE,
        related_name='reports'
    )
    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='comment_reports'
    )
    reason = models.CharField(max_length=20, choices=REASON_CHOICES)
    description = models.TextField(max_length=500, blank=True)

    # 관리자 처리 정보
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    admin_note = models.TextField(max_length=500, blank=True)

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'comment_reports'
        verbose_name = '댓글 신고'
        verbose_name_plural = '댓글 신고'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', '-created_at']),
            models.Index(fields=['comment']),
        ]
        # 동일 사용자가 동일 댓글을 중복 신고할 수 없음
        unique_together = ['comment', 'reporter']

    def __str__(self):
        return f"{self.reporter.nickname} → Comment#{self.comment.id} ({self.get_reason_display()})"

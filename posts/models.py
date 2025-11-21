from django.db import models
from django.conf import settings
from django.utils import timezone
from django.utils.translation import gettext_lazy as _


class Hashtag(models.Model):
    """Hashtag model for categorizing posts"""
    name = models.CharField(max_length=50, unique=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']
        verbose_name = 'Hashtag'
        verbose_name_plural = 'Hashtags'

    def __str__(self):
        return f"#{self.name}"


class Post(models.Model):
    """Post model for user-generated content"""

    LANGUAGE_CHOICES = [
        ('EN', '🇺🇸 English'),
        ('KO', '🇰🇷 한국어'),
        ('JA', '🇯🇵 日本語'),
        ('ZH', '🇨🇳 中文'),
        ('ES', '🇪🇸 Español'),
        ('FR', '🇫🇷 Français'),
        ('DE', '🇩🇪 Deutsch'),
    ]

    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='posts'
    )
    content = models.TextField(max_length=1000)
    native_language = models.CharField(
        max_length=2,
        choices=LANGUAGE_CHOICES,
        blank=True
    )
    target_language = models.CharField(
        max_length=2,
        choices=LANGUAGE_CHOICES,
        blank=True
    )
    hashtags = models.ManyToManyField(
        Hashtag,
        related_name='posts',
        blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Deletion tracking (for report-based deletion)
    original_content = models.TextField(
        max_length=1000,
        blank=True,
        verbose_name='원본 내용',
        help_text='삭제 전 원본 보존 (관리자 전용)'
    )
    is_deleted_by_report = models.BooleanField(
        default=False,
        db_index=True,
        verbose_name='신고로 삭제됨'
    )
    deleted_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='삭제 시각'
    )
    deletion_reason = models.CharField(
        max_length=20,
        blank=True,
        verbose_name='삭제 사유'
    )

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Post'
        verbose_name_plural = 'Posts'

    def __str__(self):
        return f"{self.author.nickname}: {self.content[:50]}..."

    def delete_by_report(self, report_type, admin_user=None):
        """
        신고로 인한 소프트 삭제 - 원본 보존
        """
        if not self.is_deleted_by_report:
            # 원본 내용 보존
            self.original_content = self.content

            # 내용을 삭제 메시지로 변경
            self.content = "게시물은 신고에 의해 삭제되었습니다."

            # 삭제 메타데이터 설정
            self.is_deleted_by_report = True
            self.deleted_at = timezone.now()
            self.deletion_reason = report_type

            self.save(update_fields=[
                'content', 'original_content',
                'is_deleted_by_report', 'deleted_at', 'deletion_reason'
            ])

            return True
        return False

    def get_content_for_user(self, user):
        """
        사용자 역할에 따른 적절한 내용 반환
        - Admin/staff: original_content with deletion flag
        - Regular user: deletion message
        """
        if self.is_deleted_by_report:
            if user and (user.is_staff or user.is_superuser):
                return {
                    'content': self.original_content,
                    'is_deleted': True,
                    'deleted_at': self.deleted_at,
                    'deletion_reason': self.get_deletion_reason_display() if self.deletion_reason else None,
                    'admin_view': True
                }
            else:
                return {
                    'content': self.content,  # "게시물은 신고에 의해 삭제되었습니다."
                    'is_deleted': True,
                    'admin_view': False
                }
        else:
            return {
                'content': self.content,
                'is_deleted': False
            }

    def get_deletion_reason_display(self):
        """Get display text for deletion reason"""
        REPORT_TYPES_DICT = dict([
            ('abuse', _('욕설/비방')),
            ('spam', _('스팸/광고')),
            ('inappropriate', _('부적절한 내용')),
            ('harassment', _('성희롱')),
            ('other', _('기타'))
        ])
        return REPORT_TYPES_DICT.get(self.deletion_reason, self.deletion_reason)


class Like(models.Model):
    """Like model for post likes"""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='likes'
    )
    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name='likes'
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ['-created_at']
        unique_together = ['user', 'post']  # Prevent duplicate likes
        verbose_name = 'Like'
        verbose_name_plural = 'Likes'
        indexes = [
            models.Index(fields=['post', '-created_at']),
        ]

    def __str__(self):
        return f"{self.user.nickname} likes {self.post.id}"


class Comment(models.Model):
    """Comment model for post comments"""
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='comments'
    )
    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name='comments'
    )
    content = models.TextField(max_length=500)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Soft delete fields for report-based deletion
    original_content = models.TextField(blank=True, null=True, help_text="Original content before deletion")
    is_deleted_by_report = models.BooleanField(default=False, db_index=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    deletion_reason = models.CharField(max_length=100, blank=True, null=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Comment'
        verbose_name_plural = 'Comments'
        indexes = [
            models.Index(fields=['post', '-created_at']),
        ]

    def __str__(self):
        return f"{self.author.nickname}: {self.content[:50]}..."

    def delete_by_report(self, reason="신고로 인해 삭제됨"):
        """Soft delete comment by marking it as deleted due to reports"""
        if not self.is_deleted_by_report:
            self.original_content = self.content
            self.content = "신고로 삭제됨"
            self.is_deleted_by_report = True
            self.deleted_at = timezone.now()
            self.deletion_reason = reason
            self.save()
            return True
        return False


class PostFavorite(models.Model):
    """User's favorite posts for bookmarking"""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='favorite_posts',
        verbose_name='User'
    )
    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name='favorited_by',
        verbose_name='Post'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Favorited At')

    class Meta:
        unique_together = ('user', 'post')
        ordering = ['-created_at']
        verbose_name = 'Post Favorite'
        verbose_name_plural = 'Post Favorites'
        indexes = [
            models.Index(fields=['user', '-created_at']),
        ]

    def __str__(self):
        return f"{self.user.nickname} favorited {self.post.id}"


class PostReport(models.Model):
    """
    Post report system for content moderation
    """
    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='post_reports_made',
        verbose_name='Reporter'
    )
    reported_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='post_reports_received',
        verbose_name='Reported User'
    )
    post = models.ForeignKey(
        Post,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reports',
        verbose_name='Post'
    )

    REPORT_TYPES = [
        ('abuse', _('욕설/비방')),
        ('spam', _('스팸/광고')),
        ('inappropriate', _('부적절한 내용')),
        ('harassment', _('성희롱')),
        ('other', _('기타'))
    ]
    report_type = models.CharField(max_length=20, choices=REPORT_TYPES, verbose_name='Report Type')
    description = models.TextField(blank=True, verbose_name='Description')

    STATUS_CHOICES = [
        ('pending', '대기 중'),
        ('reviewing', '검토 중'),
        ('resolved', '처리 완료'),
        ('dismissed', '기각')
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending',
        verbose_name='Status'
    )

    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Created At')
    reviewed_at = models.DateTimeField(null=True, blank=True, verbose_name='Reviewed At')
    admin_note = models.TextField(blank=True, verbose_name='Admin Note')

    # Admin tracking
    resolved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reports_resolved',
        verbose_name='처리한 관리자'
    )

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Post Report'
        verbose_name_plural = 'Post Reports'
        indexes = [
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['reported_user', 'status']),
            models.Index(fields=['report_type', 'created_at']),
            models.Index(fields=['reporter', 'status']),
        ]

    def __str__(self):
        post_preview = f"Post {self.post.id}" if self.post else "Deleted Post"
        return f"Report: {self.reporter.username} → {post_preview} ({self.get_report_type_display()})"

    def is_active(self):
        """Check if report is active (resolved within 1 month)"""
        if self.status == 'resolved' and self.reviewed_at:
            from django.utils import timezone
            from datetime import timedelta
            return timezone.now() - self.reviewed_at < timedelta(days=30)
        return False

    def reset_date(self):
        """Get date when report will be reset (1 month after reviewed_at)"""
        if self.reviewed_at:
            from datetime import timedelta
            return self.reviewed_at + timedelta(days=30)
        return None


class CommentReport(models.Model):
    """Report system for comments"""

    REPORT_TYPES = [
        ('abuse', _('욕설/비방')),
        ('spam', _('스팸/광고')),
        ('inappropriate', _('부적절한 내용')),
        ('harassment', _('성희롱')),
        ('other', _('기타')),
    ]

    STATUS_CHOICES = [
        ('pending', '대기 중'),
        ('reviewing', '검토 중'),
        ('resolved', '처리 완료'),
        ('dismissed', '기각'),
    ]

    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='comment_reports_made',
        verbose_name='신고자'
    )
    reported_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='comment_reports_received',
        verbose_name='피신고자'
    )
    comment = models.ForeignKey(
        Comment,
        on_delete=models.CASCADE,
        related_name='reports',
        verbose_name='신고된 댓글'
    )
    report_type = models.CharField(
        max_length=20,
        choices=REPORT_TYPES,
        verbose_name='신고 유형'
    )
    description = models.TextField(
        blank=True,
        null=True,
        verbose_name='상세 내용'
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending',
        verbose_name='처리 상태',
        db_index=True
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True, verbose_name='신고 시간')
    reviewed_at = models.DateTimeField(null=True, blank=True, verbose_name='검토 시간')
    admin_note = models.TextField(blank=True, null=True, verbose_name='관리자 메모')
    resolved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='comment_reports_resolved',
        verbose_name='처리한 관리자'
    )

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Comment Report'
        verbose_name_plural = 'Comment Reports'
        indexes = [
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['reported_user', 'status']),
            models.Index(fields=['report_type', 'created_at']),
            models.Index(fields=['reporter', 'status']),
        ]

    def __str__(self):
        comment_preview = f"Comment {self.comment.id}" if self.comment else "Deleted Comment"
        return f"Report: {self.reporter.username} → {comment_preview} ({self.get_report_type_display()})"

    def is_active(self):
        """Check if report is active (resolved within 1 month)"""
        if self.status == 'resolved' and self.reviewed_at:
            from django.utils import timezone
            from datetime import timedelta
            return timezone.now() - self.reviewed_at < timedelta(days=30)
        return False

    def reset_date(self):
        """Get date when report will be reset (1 month after reviewed_at)"""
        if self.reviewed_at:
            from datetime import timedelta
            return self.reviewed_at + timedelta(days=30)
        return None

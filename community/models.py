from django.db import models
from django.conf import settings


class Post(models.Model):
    """
    MarketLens 커뮤니티 게시글 모델
    - 종목별 게시판
    - 최신순 정렬 (기본값)
    - HypeHere posts 앱과 완전 분리
    """
    ticker = models.CharField(max_length=10, db_index=True, help_text="종목 심볼 (대문자)")
    title = models.CharField(max_length=200)
    content = models.TextField(max_length=5000)
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='community_posts'
    )

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    # 성능 최적화용 역정규화 카운터
    like_count = models.IntegerField(default=0)
    comment_count = models.IntegerField(default=0)
    view_count = models.IntegerField(default=0)

    # 소프트 삭제 및 숨김 처리
    is_deleted = models.BooleanField(default=False)
    is_hidden = models.BooleanField(default=False)

    class Meta:
        db_table = 'community_posts'
        verbose_name = '커뮤니티 게시글'
        verbose_name_plural = '커뮤니티 게시글'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['-created_at']),
            models.Index(fields=['ticker', '-created_at']),
            models.Index(fields=['-like_count']),
            models.Index(fields=['-comment_count']),
        ]

    def save(self, *args, **kwargs):
        """ticker를 대문자로 자동 변환"""
        if self.ticker:
            self.ticker = self.ticker.upper()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"[{self.ticker}] {self.title}"

    def increment_comment_count(self):
        self.comment_count += 1
        self.save(update_fields=['comment_count'])

    def decrement_comment_count(self):
        if self.comment_count > 0:
            self.comment_count -= 1
            self.save(update_fields=['comment_count'])

    def increment_like_count(self):
        self.like_count += 1
        self.save(update_fields=['like_count'])

    def decrement_like_count(self):
        if self.like_count > 0:
            self.like_count -= 1
            self.save(update_fields=['like_count'])


class Comment(models.Model):
    """
    댓글 모델
    - 로그인 필수 (비회원은 조회 불가)
    - 대댓글 지원
    """
    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name='comments'
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='community_comments'
    )
    content = models.TextField(max_length=1000)

    # 대댓글 지원
    parent = models.ForeignKey(
        'self',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='replies'
    )

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    # 성능 최적화용 역정규화 카운터
    like_count = models.IntegerField(default=0)

    # 소프트 삭제
    is_deleted = models.BooleanField(default=False)

    class Meta:
        db_table = 'community_comments'
        verbose_name = '커뮤니티 댓글'
        verbose_name_plural = '커뮤니티 댓글'
        ordering = ['created_at']
        indexes = [
            models.Index(fields=['post', 'created_at']),
            models.Index(fields=['parent']),
        ]

    def __str__(self):
        return f"{self.author.nickname}: {self.content[:30]}"

    def increment_like_count(self):
        self.like_count += 1
        self.save(update_fields=['like_count'])

    def decrement_like_count(self):
        if self.like_count > 0:
            self.like_count -= 1
            self.save(update_fields=['like_count'])


class PostLike(models.Model):
    """
    게시글 좋아요 모델
    - 사용자당 1회 제한
    """
    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name='likes'
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='community_post_likes'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'community_post_likes'
        verbose_name = '게시글 좋아요'
        verbose_name_plural = '게시글 좋아요'
        unique_together = ['post', 'user']
        indexes = [
            models.Index(fields=['post']),
            models.Index(fields=['user']),
        ]

    def __str__(self):
        return f"{self.user.nickname} → {self.post.title}"


class CommentLike(models.Model):
    """
    댓글 좋아요 모델
    - 사용자당 1회 제한
    """
    comment = models.ForeignKey(
        Comment,
        on_delete=models.CASCADE,
        related_name='likes'
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='community_comment_likes'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'community_comment_likes'
        verbose_name = '댓글 좋아요'
        verbose_name_plural = '댓글 좋아요'
        unique_together = ['comment', 'user']
        indexes = [
            models.Index(fields=['comment']),
            models.Index(fields=['user']),
        ]

    def __str__(self):
        return f"{self.user.nickname} → Comment#{self.comment.id}"


class PostReport(models.Model):
    """
    게시글 신고 모델
    - 신고 3건 이상 → 자동 숨김
    """
    REPORT_TYPES = [
        ('abuse', '욕설/비방'),
        ('spam', '스팸/광고'),
        ('inappropriate', '부적절한 내용'),
        ('harassment', '성희롱'),
        ('other', '기타'),
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
        related_name='community_post_reports_made'
    )
    reported_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='community_post_reports_received'
    )
    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name='reports'
    )
    report_type = models.CharField(max_length=20, choices=REPORT_TYPES)
    description = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending', db_index=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    admin_note = models.TextField(blank=True)
    resolved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='community_post_reports_resolved'
    )

    class Meta:
        db_table = 'community_post_reports'
        verbose_name = '게시글 신고'
        verbose_name_plural = '게시글 신고'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['post']),
        ]

    def __str__(self):
        return f"Report: {self.reporter} → Post#{self.post_id} ({self.get_report_type_display()})"


class CommentReport(models.Model):
    """
    댓글 신고 모델
    """
    REPORT_TYPES = [
        ('abuse', '욕설/비방'),
        ('spam', '스팸/광고'),
        ('inappropriate', '부적절한 내용'),
        ('harassment', '성희롱'),
        ('other', '기타'),
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
        related_name='community_comment_reports_made'
    )
    reported_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='community_comment_reports_received'
    )
    comment = models.ForeignKey(
        Comment,
        on_delete=models.CASCADE,
        related_name='reports'
    )
    report_type = models.CharField(max_length=20, choices=REPORT_TYPES)
    description = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending', db_index=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    admin_note = models.TextField(blank=True)
    resolved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='community_comment_reports_resolved'
    )

    class Meta:
        db_table = 'community_comment_reports'
        verbose_name = '댓글 신고'
        verbose_name_plural = '댓글 신고'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['comment']),
        ]

    def __str__(self):
        return f"Report: {self.reporter} → Comment#{self.comment_id} ({self.get_report_type_display()})"


class BannedKeyword(models.Model):
    """
    금칙어 모델
    - 정규식 또는 일반 텍스트 매칭
    - 게시글/댓글 작성 시 검사
    """
    keyword = models.CharField(max_length=100, unique=True)
    is_regex = models.BooleanField(default=False, help_text="정규식 패턴 여부")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'community_banned_keywords'
        verbose_name = '금칙어'
        verbose_name_plural = '금칙어'

    def __str__(self):
        prefix = "[regex] " if self.is_regex else ""
        return f"{prefix}{self.keyword}"

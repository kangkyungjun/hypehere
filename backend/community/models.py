from django.db import models
from django.conf import settings


class Post(models.Model):
    """
    커뮤니티 게시글 모델
    - 종목별 게시판
    - 최신순 정렬 (기본값)
    """
    ticker = models.CharField(max_length=10, blank=True, default='', db_index=True, help_text="종목 심볼 (대문자, 빈 문자열이면 자유 게시글)")
    title = models.CharField(max_length=200)
    content = models.TextField(max_length=5000)
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='posts'
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
        verbose_name = '게시글'
        verbose_name_plural = '게시글'
        ordering = ['-created_at']  # 기본 정렬: 최신순
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
        """댓글 수 증가"""
        self.comment_count += 1
        self.save(update_fields=['comment_count'])

    def decrement_comment_count(self):
        """댓글 수 감소"""
        if self.comment_count > 0:
            self.comment_count -= 1
            self.save(update_fields=['comment_count'])

    def increment_like_count(self):
        """좋아요 수 증가"""
        self.like_count += 1
        self.save(update_fields=['like_count'])

    def decrement_like_count(self):
        """좋아요 수 감소"""
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
        related_name='comments'
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
        verbose_name = '댓글'
        verbose_name_plural = '댓글'
        ordering = ['created_at']  # 오래된 순 (시간 흐름대로)
        indexes = [
            models.Index(fields=['post', 'created_at']),
            models.Index(fields=['parent']),
        ]

    def __str__(self):
        return f"{self.author.nickname}: {self.content[:30]}"

    def increment_like_count(self):
        """좋아요 수 증가"""
        self.like_count += 1
        self.save(update_fields=['like_count'])

    def decrement_like_count(self):
        """좋아요 수 감소"""
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
        related_name='post_likes'
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
        related_name='comment_likes'
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

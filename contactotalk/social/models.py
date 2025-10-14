from django.db import models
from django.conf import settings
from django.utils import timezone


class Post(models.Model):
    """게시글"""

    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="posts"
    )

    # 게시글 내용
    content = models.TextField(max_length=2000, help_text="게시글 내용")

    # 이미지 (최대 4개)
    image1 = models.ImageField(upload_to="posts/%Y/%m/%d/", null=True, blank=True)
    image2 = models.ImageField(upload_to="posts/%Y/%m/%d/", null=True, blank=True)
    image3 = models.ImageField(upload_to="posts/%Y/%m/%d/", null=True, blank=True)
    image4 = models.ImageField(upload_to="posts/%Y/%m/%d/", null=True, blank=True)

    # 통계
    like_count = models.IntegerField(default=0, help_text="좋아요 수")
    comment_count = models.IntegerField(default=0, help_text="댓글 수")
    view_count = models.IntegerField(default=0, help_text="조회 수")

    # 상태
    is_active = models.BooleanField(default=True, help_text="활성화 여부")

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "게시글"
        verbose_name_plural = "게시글 목록"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["-created_at"]),
            models.Index(fields=["author", "-created_at"]),
        ]

    def __str__(self):
        return f"{self.author.nickname}: {self.content[:30]}"

    def increment_like_count(self):
        """좋아요 수 증가"""
        self.like_count += 1
        self.save(update_fields=["like_count"])

    def decrement_like_count(self):
        """좋아요 수 감소"""
        if self.like_count > 0:
            self.like_count -= 1
            self.save(update_fields=["like_count"])

    def increment_comment_count(self):
        """댓글 수 증가"""
        self.comment_count += 1
        self.save(update_fields=["comment_count"])

    def decrement_comment_count(self):
        """댓글 수 감소"""
        if self.comment_count > 0:
            self.comment_count -= 1
            self.save(update_fields=["comment_count"])

    def increment_view_count(self):
        """조회 수 증가"""
        self.view_count += 1
        self.save(update_fields=["view_count"])

    def get_images(self):
        """이미지 리스트 반환"""
        images = []
        for i in range(1, 5):
            img = getattr(self, f"image{i}")
            if img:
                images.append(img.url)
        return images


class PostLike(models.Model):
    """게시글 좋아요"""

    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name="likes"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="post_likes"
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("post", "user")
        verbose_name = "게시글 좋아요"
        verbose_name_plural = "게시글 좋아요 목록"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.nickname} likes {self.post.id}"


class Comment(models.Model):
    """댓글"""

    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name="comments"
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="comments"
    )

    # 댓글 내용
    content = models.TextField(max_length=500, help_text="댓글 내용")

    # 대댓글 (부모 댓글)
    parent = models.ForeignKey(
        "self",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="replies",
        help_text="부모 댓글 (대댓글인 경우)"
    )

    # 통계
    like_count = models.IntegerField(default=0, help_text="좋아요 수")

    # 상태
    is_active = models.BooleanField(default=True, help_text="활성화 여부")

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "댓글"
        verbose_name_plural = "댓글 목록"
        ordering = ["created_at"]
        indexes = [
            models.Index(fields=["post", "created_at"]),
        ]

    def __str__(self):
        return f"{self.author.nickname}: {self.content[:30]}"

    def increment_like_count(self):
        """좋아요 수 증가"""
        self.like_count += 1
        self.save(update_fields=["like_count"])

    def decrement_like_count(self):
        """좋아요 수 감소"""
        if self.like_count > 0:
            self.like_count -= 1
            self.save(update_fields=["like_count"])


class CommentLike(models.Model):
    """댓글 좋아요"""

    comment = models.ForeignKey(
        Comment,
        on_delete=models.CASCADE,
        related_name="likes"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="comment_likes"
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("comment", "user")
        verbose_name = "댓글 좋아요"
        verbose_name_plural = "댓글 좋아요 목록"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.nickname} likes comment {self.comment.id}"


class Follow(models.Model):
    """팔로우"""

    # 팔로워 (following하는 사람)
    follower = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="following",
        help_text="팔로우하는 사람"
    )

    # 팔로잉 (followed되는 사람)
    following = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="followers",
        help_text="팔로우받는 사람"
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("follower", "following")
        verbose_name = "팔로우"
        verbose_name_plural = "팔로우 목록"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["follower", "-created_at"]),
            models.Index(fields=["following", "-created_at"]),
        ]

    def __str__(self):
        return f"{self.follower.nickname} follows {self.following.nickname}"


class UserProfile(models.Model):
    """사용자 프로필 (SNS 확장)"""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="profile"
    )

    # 프로필 정보
    bio = models.TextField(max_length=500, blank=True, help_text="자기소개")
    website = models.URLField(max_length=200, blank=True, help_text="웹사이트")
    location = models.CharField(max_length=100, blank=True, help_text="위치")

    # 프로필 이미지
    avatar = models.ImageField(
        upload_to="avatars/",
        null=True,
        blank=True,
        help_text="프로필 이미지"
    )
    cover_image = models.ImageField(
        upload_to="covers/",
        null=True,
        blank=True,
        help_text="커버 이미지"
    )

    # 통계 (캐시)
    post_count = models.IntegerField(default=0, help_text="게시글 수")
    follower_count = models.IntegerField(default=0, help_text="팔로워 수")
    following_count = models.IntegerField(default=0, help_text="팔로잉 수")

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "사용자 프로필"
        verbose_name_plural = "사용자 프로필 목록"

    def __str__(self):
        return f"{self.user.nickname}'s profile"

    def increment_post_count(self):
        """게시글 수 증가"""
        self.post_count += 1
        self.save(update_fields=["post_count"])

    def decrement_post_count(self):
        """게시글 수 감소"""
        if self.post_count > 0:
            self.post_count -= 1
            self.save(update_fields=["post_count"])

    def increment_follower_count(self):
        """팔로워 수 증가"""
        self.follower_count += 1
        self.save(update_fields=["follower_count"])

    def decrement_follower_count(self):
        """팔로워 수 감소"""
        if self.follower_count > 0:
            self.follower_count -= 1
            self.save(update_fields=["follower_count"])

    def increment_following_count(self):
        """팔로잉 수 증가"""
        self.following_count += 1
        self.save(update_fields=["following_count"])

    def decrement_following_count(self):
        """팔로잉 수 감소"""
        if self.following_count > 0:
            self.following_count -= 1
            self.save(update_fields=["following_count"])

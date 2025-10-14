from django.contrib import admin
from .models import Post, PostLike, Comment, CommentLike, Follow, UserProfile


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    """게시글 관리"""

    list_display = (
        "id",
        "author",
        "content_preview",
        "like_count",
        "comment_count",
        "view_count",
        "is_active",
        "created_at",
    )
    list_filter = ("is_active", "created_at")
    search_fields = ("author__username", "author__nickname", "content")
    raw_id_fields = ("author",)
    ordering = ("-created_at",)
    readonly_fields = ("like_count", "comment_count", "view_count", "created_at", "updated_at")

    def content_preview(self, obj):
        """내용 미리보기"""
        return obj.content[:50] + "..." if len(obj.content) > 50 else obj.content

    content_preview.short_description = "내용"


@admin.register(PostLike)
class PostLikeAdmin(admin.ModelAdmin):
    """게시글 좋아요 관리"""

    list_display = ("id", "user", "post", "created_at")
    list_filter = ("created_at",)
    search_fields = ("user__username", "user__nickname", "post__content")
    raw_id_fields = ("post", "user")
    ordering = ("-created_at",)


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    """댓글 관리"""

    list_display = (
        "id",
        "author",
        "post",
        "content_preview",
        "parent",
        "like_count",
        "is_active",
        "created_at",
    )
    list_filter = ("is_active", "created_at")
    search_fields = ("author__username", "author__nickname", "content")
    raw_id_fields = ("post", "author", "parent")
    ordering = ("-created_at",)
    readonly_fields = ("like_count", "created_at", "updated_at")

    def content_preview(self, obj):
        """내용 미리보기"""
        return obj.content[:50] + "..." if len(obj.content) > 50 else obj.content

    content_preview.short_description = "내용"


@admin.register(CommentLike)
class CommentLikeAdmin(admin.ModelAdmin):
    """댓글 좋아요 관리"""

    list_display = ("id", "user", "comment", "created_at")
    list_filter = ("created_at",)
    search_fields = ("user__username", "user__nickname", "comment__content")
    raw_id_fields = ("comment", "user")
    ordering = ("-created_at",)


@admin.register(Follow)
class FollowAdmin(admin.ModelAdmin):
    """팔로우 관리"""

    list_display = ("id", "follower", "following", "created_at")
    list_filter = ("created_at",)
    search_fields = ("follower__username", "follower__nickname", "following__username", "following__nickname")
    raw_id_fields = ("follower", "following")
    ordering = ("-created_at",)


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    """사용자 프로필 관리"""

    list_display = (
        "user",
        "bio_preview",
        "location",
        "post_count",
        "follower_count",
        "following_count",
        "created_at",
    )
    list_filter = ("created_at",)
    search_fields = ("user__username", "user__nickname", "bio", "location")
    raw_id_fields = ("user",)
    ordering = ("-created_at",)
    readonly_fields = ("post_count", "follower_count", "following_count", "created_at", "updated_at")

    def bio_preview(self, obj):
        """자기소개 미리보기"""
        if obj.bio:
            return obj.bio[:30] + "..." if len(obj.bio) > 30 else obj.bio
        return "-"

    bio_preview.short_description = "자기소개"

from django.contrib import admin
from .models import Post, Comment, PostLike, CommentLike, PostReport, CommentReport, BannedKeyword


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    """게시글 관리자"""

    list_display = ['id', 'ticker', 'title', 'author', 'like_count', 'comment_count',
                   'view_count', 'created_at', 'is_deleted', 'is_hidden']
    list_filter = ['ticker', 'is_deleted', 'is_hidden', 'created_at']
    search_fields = ['title', 'content', 'ticker', 'author__nickname', 'author__email']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at', 'like_count', 'comment_count', 'view_count']

    fieldsets = (
        ('기본 정보', {
            'fields': ('ticker', 'title', 'content', 'author')
        }),
        ('통계', {
            'fields': ('like_count', 'comment_count', 'view_count')
        }),
        ('상태', {
            'fields': ('is_deleted', 'is_hidden')
        }),
        ('날짜', {
            'fields': ('created_at', 'updated_at')
        }),
    )


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    """댓글 관리자"""

    list_display = ['id', 'post', 'author', 'content_preview', 'parent',
                   'like_count', 'created_at', 'is_deleted']
    list_filter = ['is_deleted', 'created_at']
    search_fields = ['content', 'author__nickname', 'author__email', 'post__title']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at', 'like_count']

    def content_preview(self, obj):
        """댓글 내용 미리보기"""
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = '내용'

    fieldsets = (
        ('기본 정보', {
            'fields': ('post', 'author', 'content', 'parent')
        }),
        ('통계', {
            'fields': ('like_count',)
        }),
        ('상태', {
            'fields': ('is_deleted',)
        }),
        ('날짜', {
            'fields': ('created_at', 'updated_at')
        }),
    )


@admin.register(PostLike)
class PostLikeAdmin(admin.ModelAdmin):
    """게시글 좋아요 관리자"""

    list_display = ['id', 'post', 'user', 'created_at']
    list_filter = ['created_at']
    search_fields = ['post__title', 'user__nickname', 'user__email']
    ordering = ['-created_at']
    readonly_fields = ['created_at']


@admin.register(CommentLike)
class CommentLikeAdmin(admin.ModelAdmin):
    """댓글 좋아요 관리자"""

    list_display = ['id', 'comment', 'user', 'created_at']
    list_filter = ['created_at']
    search_fields = ['comment__content', 'user__nickname', 'user__email']
    ordering = ['-created_at']
    readonly_fields = ['created_at']


@admin.register(PostReport)
class PostReportAdmin(admin.ModelAdmin):
    """게시글 신고 관리자"""

    list_display = ['id', 'reporter', 'reported_user', 'post', 'report_type', 'status', 'created_at']
    list_filter = ['report_type', 'status', 'created_at']
    search_fields = ['reporter__nickname', 'reported_user__nickname', 'post__title']
    ordering = ['-created_at']
    readonly_fields = ['created_at']


@admin.register(CommentReport)
class CommentReportAdmin(admin.ModelAdmin):
    """댓글 신고 관리자"""

    list_display = ['id', 'reporter', 'reported_user', 'comment', 'report_type', 'status', 'created_at']
    list_filter = ['report_type', 'status', 'created_at']
    search_fields = ['reporter__nickname', 'reported_user__nickname']
    ordering = ['-created_at']
    readonly_fields = ['created_at']


@admin.register(BannedKeyword)
class BannedKeywordAdmin(admin.ModelAdmin):
    """금칙어 관리자"""

    list_display = ['id', 'keyword', 'is_regex', 'is_active', 'created_at']
    list_filter = ['is_regex', 'is_active']
    search_fields = ['keyword']
    ordering = ['-created_at']

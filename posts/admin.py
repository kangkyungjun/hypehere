from django.contrib import admin
from .models import Post, Hashtag, Like, Comment, PostReport, CommentReport


@admin.register(Hashtag)
class HashtagAdmin(admin.ModelAdmin):
    """Admin configuration for Hashtag model"""
    list_display = ('name', 'post_count', 'created_at')
    search_fields = ('name',)
    ordering = ('name',)
    readonly_fields = ('created_at',)

    def post_count(self, obj):
        """Display number of posts with this hashtag"""
        return obj.posts.count()
    post_count.short_description = 'Posts'


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    """Admin configuration for Post model"""
    list_display = ('id', 'author', 'content_preview', 'like_count', 'comment_count',
                    'native_language', 'target_language', 'created_at')
    list_filter = ('native_language', 'target_language', 'created_at')
    search_fields = ('content', 'author__email', 'author__nickname')
    readonly_fields = ('created_at', 'updated_at')
    filter_horizontal = ('hashtags',)
    ordering = ('-created_at',)

    def content_preview(self, obj):
        """Display first 50 characters of content"""
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'

    def like_count(self, obj):
        return obj.likes.count()
    like_count.short_description = 'Likes'

    def comment_count(self, obj):
        return obj.comments.count()
    comment_count.short_description = 'Comments'


@admin.register(Like)
class LikeAdmin(admin.ModelAdmin):
    """Admin configuration for Like model"""
    list_display = ('user', 'post', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('user__email', 'user__nickname', 'post__content')
    readonly_fields = ('created_at',)
    ordering = ('-created_at',)


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    """Admin configuration for Comment model"""
    list_display = ('id', 'author', 'post', 'content_preview', 'created_at')
    list_filter = ('created_at', 'updated_at')
    search_fields = ('content', 'author__email', 'author__nickname', 'post__content')
    readonly_fields = ('created_at', 'updated_at')
    ordering = ('-created_at',)

    def content_preview(self, obj):
        """Display first 50 characters of content"""
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'


@admin.register(PostReport)
class PostReportAdmin(admin.ModelAdmin):
    """Admin configuration for PostReport model"""
    list_display = ('id', 'reporter', 'reported_user', 'post_preview', 'report_type', 'status', 'created_at')
    list_filter = ('status', 'report_type', 'created_at')
    search_fields = ('reporter__email', 'reporter__nickname', 'reported_user__email',
                     'reported_user__nickname', 'post__content', 'description')
    readonly_fields = ('created_at', 'reviewed_at')
    ordering = ('-created_at',)

    fieldsets = (
        ('Report Information', {
            'fields': ('reporter', 'reported_user', 'post', 'report_type', 'description')
        }),
        ('Status', {
            'fields': ('status', 'admin_note', 'created_at', 'reviewed_at')
        }),
    )

    def post_preview(self, obj):
        """Display post content preview"""
        if obj.post:
            content = obj.post.content
            return content[:50] + '...' if len(content) > 50 else content
        return 'Deleted Post'
    post_preview.short_description = 'Post'


@admin.register(CommentReport)
class CommentReportAdmin(admin.ModelAdmin):
    """Admin configuration for CommentReport model"""
    list_display = ('id', 'reporter', 'reported_user', 'comment_preview', 'report_type', 'status', 'created_at')
    list_filter = ('status', 'report_type', 'created_at')
    search_fields = ('reporter__email', 'reporter__nickname', 'reported_user__email',
                     'reported_user__nickname', 'comment__content', 'description')
    readonly_fields = ('created_at', 'reviewed_at')
    ordering = ('-created_at',)

    fieldsets = (
        ('Report Information', {
            'fields': ('reporter', 'reported_user', 'comment', 'report_type', 'description')
        }),
        ('Status', {
            'fields': ('status', 'admin_note', 'created_at', 'reviewed_at')
        }),
    )

    def comment_preview(self, obj):
        """Display comment content preview"""
        if obj.comment:
            content = obj.comment.content
            return content[:50] + '...' if len(content) > 50 else content
        return 'Deleted Comment'
    comment_preview.short_description = 'Comment'

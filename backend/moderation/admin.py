from django.contrib import admin
from .models import PostReport, CommentReport, BlockedUser


@admin.register(BlockedUser)
class BlockedUserAdmin(admin.ModelAdmin):
    """사용자 차단 관리자 (차단 발생 모니터링 — 개발자 통보)"""

    list_display = ['id', 'blocker', 'blocked', 'reason', 'created_at']
    list_filter = ['created_at']
    search_fields = ['blocker__nickname', 'blocked__nickname', 'reason']
    ordering = ['-created_at']
    readonly_fields = ['created_at']
    raw_id_fields = ['blocker', 'blocked', 'context_post', 'context_comment']


@admin.register(PostReport)
class PostReportAdmin(admin.ModelAdmin):
    """게시글 신고 관리자"""

    list_display = ['id', 'post', 'reporter', 'reason', 'status', 'created_at']
    list_filter = ['status', 'reason', 'created_at']
    search_fields = ['post__title', 'reporter__nickname', 'description', 'admin_note']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at']

    fieldsets = (
        ('신고 정보', {
            'fields': ('post', 'reporter', 'reason', 'description')
        }),
        ('처리 상태', {
            'fields': ('status', 'admin_note')
        }),
        ('날짜', {
            'fields': ('created_at', 'updated_at')
        }),
    )

    actions = ['mark_as_reviewing', 'mark_as_resolved', 'mark_as_dismissed']

    def mark_as_reviewing(self, request, queryset):
        """검토중으로 변경"""
        updated = queryset.update(status='reviewing')
        self.message_user(request, f'{updated}개의 신고를 검토중으로 변경했습니다.')
    mark_as_reviewing.short_description = '선택된 신고를 검토중으로 변경'

    def mark_as_resolved(self, request, queryset):
        """처리완료로 변경"""
        updated = queryset.update(status='resolved')
        self.message_user(request, f'{updated}개의 신고를 처리완료로 변경했습니다.')
    mark_as_resolved.short_description = '선택된 신고를 처리완료로 변경'

    def mark_as_dismissed(self, request, queryset):
        """기각으로 변경"""
        updated = queryset.update(status='dismissed')
        self.message_user(request, f'{updated}개의 신고를 기각으로 변경했습니다.')
    mark_as_dismissed.short_description = '선택된 신고를 기각으로 변경'


@admin.register(CommentReport)
class CommentReportAdmin(admin.ModelAdmin):
    """댓글 신고 관리자"""

    list_display = ['id', 'comment', 'reporter', 'reason', 'status', 'created_at']
    list_filter = ['status', 'reason', 'created_at']
    search_fields = ['comment__content', 'reporter__nickname', 'description', 'admin_note']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at']

    fieldsets = (
        ('신고 정보', {
            'fields': ('comment', 'reporter', 'reason', 'description')
        }),
        ('처리 상태', {
            'fields': ('status', 'admin_note')
        }),
        ('날짜', {
            'fields': ('created_at', 'updated_at')
        }),
    )

    actions = ['mark_as_reviewing', 'mark_as_resolved', 'mark_as_dismissed']

    def mark_as_reviewing(self, request, queryset):
        """검토중으로 변경"""
        updated = queryset.update(status='reviewing')
        self.message_user(request, f'{updated}개의 신고를 검토중으로 변경했습니다.')
    mark_as_reviewing.short_description = '선택된 신고를 검토중으로 변경'

    def mark_as_resolved(self, request, queryset):
        """처리완료로 변경"""
        updated = queryset.update(status='resolved')
        self.message_user(request, f'{updated}개의 신고를 처리완료로 변경했습니다.')
    mark_as_resolved.short_description = '선택된 신고를 처리완료로 변경'

    def mark_as_dismissed(self, request, queryset):
        """기각으로 변경"""
        updated = queryset.update(status='dismissed')
        self.message_user(request, f'{updated}개의 신고를 기각으로 변경했습니다.')
    mark_as_dismissed.short_description = '선택된 신고를 기각으로 변경'

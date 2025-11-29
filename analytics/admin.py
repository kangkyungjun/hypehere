from django.contrib import admin
from .models import DailyVisitor, UserActivityLog, AnonymousChatUsageStats, DailySummary


@admin.register(DailyVisitor)
class DailyVisitorAdmin(admin.ModelAdmin):
    list_display = ['date', 'ip_address', 'user', 'visit_count', 'first_visit', 'last_visit']
    list_filter = ['date', 'user']
    search_fields = ['ip_address', 'user__email']
    readonly_fields = ['date', 'first_visit', 'last_visit']
    ordering = ['-date', '-last_visit']


@admin.register(UserActivityLog)
class UserActivityLogAdmin(admin.ModelAdmin):
    list_display = ['user', 'date', 'page_views', 'posts_created', 'comments_created', 'messages_sent', 'last_activity']
    list_filter = ['date']
    search_fields = ['user__email', 'user__nickname']
    readonly_fields = ['date', 'last_activity']
    ordering = ['-date', '-last_activity']


@admin.register(AnonymousChatUsageStats)
class AnonymousChatUsageStatsAdmin(admin.ModelAdmin):
    list_display = ['user', 'date', 'conversations_started', 'messages_sent', 'total_duration_seconds', 'updated_at']
    list_filter = ['date']
    search_fields = ['user__email', 'user__nickname']
    readonly_fields = ['date', 'created_at', 'updated_at']
    ordering = ['-date', '-updated_at']


@admin.register(DailySummary)
class DailySummaryAdmin(admin.ModelAdmin):
    list_display = ['date', 'unique_visitors', 'new_users', 'active_users', 'posts_created', 'anonymous_chat_users', 'updated_at']
    list_filter = ['date']
    readonly_fields = ['created_at', 'updated_at']
    ordering = ['-date']

    fieldsets = (
        ('Date', {
            'fields': ('date',)
        }),
        ('Visitor Statistics', {
            'fields': ('unique_visitors', 'total_page_views')
        }),
        ('User Statistics', {
            'fields': ('new_users', 'active_users')
        }),
        ('Content Statistics', {
            'fields': ('posts_created', 'comments_created')
        }),
        ('Chat Statistics', {
            'fields': ('anonymous_chat_users', 'anonymous_chat_conversations', 'anonymous_chat_messages')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )

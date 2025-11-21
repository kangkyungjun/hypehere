from django.contrib import admin
from .models import Notification


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    """알림 관리자 인터페이스"""

    list_display = [
        'id',
        'notification_type',
        'recipient',
        'sender',
        'text_preview_short',
        'is_read',
        'created_at'
    ]
    list_filter = ['notification_type', 'is_read', 'created_at']
    search_fields = ['recipient__nickname', 'sender__nickname', 'text_preview']
    readonly_fields = ['created_at']
    list_per_page = 50

    def text_preview_short(self, obj):
        """미리보기 텍스트 짧게 표시"""
        if obj.text_preview:
            return obj.text_preview[:50] + '...' if len(obj.text_preview) > 50 else obj.text_preview
        return '-'
    text_preview_short.short_description = '미리보기'

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import CustomUser, EmailVerificationCode


@admin.register(CustomUser)
class CustomUserAdmin(BaseUserAdmin):
    """CustomUser 관리자 설정"""

    list_display = ['email', 'nickname', 'is_email_verified', 'is_staff', 'is_active', 'created_at']
    list_filter = ['is_staff', 'is_active', 'is_email_verified', 'created_at']
    search_fields = ['email', 'nickname', 'username']
    ordering = ['-created_at']

    # 필드 그룹 설정
    fieldsets = (
        ('계정 정보', {
            'fields': ('email', 'password')
        }),
        ('개인 정보', {
            'fields': ('nickname', 'profile_picture', 'bio', 'watchlist_tickers')
        }),
        ('권한', {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'is_email_verified', 'groups', 'user_permissions')
        }),
        ('중요한 날짜', {
            'fields': ('last_login', 'date_joined')
        }),
    )

    # 사용자 추가 폼 필드
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'nickname', 'password1', 'password2'),
        }),
    )

    readonly_fields = ['last_login', 'date_joined']


@admin.register(EmailVerificationCode)
class EmailVerificationCodeAdmin(admin.ModelAdmin):
    list_display = ['email', 'purpose', 'code', 'is_used', 'attempts', 'created_at', 'expires_at']
    list_filter = ['purpose', 'is_used']
    search_fields = ['email']
    ordering = ['-created_at']
    readonly_fields = ['created_at']

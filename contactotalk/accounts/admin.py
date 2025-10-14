from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, Interest, UserInterest


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """커스텀 사용자 관리 페이지"""

    list_display = (
        "username",
        "nickname",
        "role",
        "country_code",
        "is_active",
        "is_banned",
        "daily_match_count",
        "created_at",
    )
    list_filter = (
        "role",
        "is_active",
        "is_banned",
        "country_code",
        "created_at",
    )
    search_fields = ("username", "nickname", "email")
    ordering = ("-created_at",)

    fieldsets = BaseUserAdmin.fieldsets + (
        (
            "추가 정보",
            {
                "fields": (
                    "role",
                    "nickname",
                    "country_code",
                    "bio",
                )
            },
        ),
        (
            "프리미엄",
            {
                "fields": (
                    "premium_until",
                )
            },
        ),
        (
            "매칭 제한",
            {
                "fields": (
                    "daily_match_count",
                    "last_match_reset",
                )
            },
        ),
        (
            "계정 상태",
            {
                "fields": (
                    "is_banned",
                    "banned_until",
                )
            },
        ),
    )


@admin.register(Interest)
class InterestAdmin(admin.ModelAdmin):
    """관심사 관리 페이지"""

    list_display = (
        "id",
        "category",
        "name_ko",
        "name_en",
        "icon",
        "created_at",
    )
    list_filter = ("category",)
    search_fields = ("name", "name_ko", "name_en")
    ordering = ("category", "name")


@admin.register(UserInterest)
class UserInterestAdmin(admin.ModelAdmin):
    """사용자-관심사 관리 페이지"""

    list_display = (
        "user",
        "interest",
        "created_at",
    )
    list_filter = ("interest__category",)
    search_fields = ("user__username", "interest__name_ko")
    raw_id_fields = ("user", "interest")

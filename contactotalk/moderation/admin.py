from django.contrib import admin
from .models import Report, UserSanction, ModerationLog


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    """신고 관리"""

    list_display = [
        "id",
        "reporter",
        "report_type",
        "reason",
        "status",
        "reviewer",
        "created_at",
    ]
    list_filter = ["status", "report_type", "reason", "created_at"]
    search_fields = ["reporter__nickname", "reporter__email", "description"]
    readonly_fields = ["reporter", "report_type", "content_type", "object_id", "created_at", "updated_at"]
    list_per_page = 50

    fieldsets = (
        (
            "신고 정보",
            {
                "fields": (
                    "reporter",
                    "report_type",
                    "content_type",
                    "object_id",
                    "reason",
                    "description",
                )
            },
        ),
        (
            "처리 정보",
            {
                "fields": (
                    "status",
                    "reviewer",
                    "resolution",
                    "resolved_at",
                )
            },
        ),
        ("타임스탬프", {"fields": ("created_at", "updated_at")}),
    )

    def has_add_permission(self, request):
        """관리자 페이지에서 직접 신고 추가 불가"""
        return False


@admin.register(UserSanction)
class UserSanctionAdmin(admin.ModelAdmin):
    """사용자 제재 관리"""

    list_display = [
        "id",
        "user",
        "sanction_type",
        "sanctioned_by",
        "start_date",
        "end_date",
        "is_active",
        "created_at",
    ]
    list_filter = ["sanction_type", "is_active", "created_at"]
    search_fields = ["user__nickname", "user__email", "reason"]
    readonly_fields = ["created_at", "updated_at"]
    list_per_page = 50

    fieldsets = (
        (
            "제재 대상",
            {
                "fields": ("user",)
            },
        ),
        (
            "제재 정보",
            {
                "fields": (
                    "sanction_type",
                    "reason",
                    "start_date",
                    "end_date",
                    "is_active",
                )
            },
        ),
        (
            "제재자 및 관련 정보",
            {
                "fields": (
                    "sanctioned_by",
                    "related_report",
                )
            },
        ),
        ("타임스탬프", {"fields": ("created_at", "updated_at")}),
    )


@admin.register(ModerationLog)
class ModerationLogAdmin(admin.ModelAdmin):
    """관리 로그"""

    list_display = [
        "id",
        "moderator",
        "action_type",
        "description",
        "created_at",
    ]
    list_filter = ["action_type", "created_at"]
    search_fields = ["moderator__nickname", "moderator__email", "description"]
    readonly_fields = ["moderator", "action_type", "content_type", "object_id", "description", "created_at"]
    list_per_page = 100

    fieldsets = (
        (
            "관리자 정보",
            {
                "fields": ("moderator",)
            },
        ),
        (
            "액션 정보",
            {
                "fields": (
                    "action_type",
                    "description",
                    "content_type",
                    "object_id",
                )
            },
        ),
        ("타임스탬프", {"fields": ("created_at",)}),
    )

    def has_add_permission(self, request):
        """관리자 페이지에서 직접 로그 추가 불가"""
        return False

    def has_delete_permission(self, request, obj=None):
        """로그는 삭제 불가 (감사 추적을 위해)"""
        return False

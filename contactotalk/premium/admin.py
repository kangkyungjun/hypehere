from django.contrib import admin
from .models import Subscription, UserSubscription, Payment, Advertisement, AdImpression


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    """구독 플랜 관리"""

    list_display = [
        "id",
        "name",
        "plan_type",
        "price",
        "duration_days",
        "is_ad_free",
        "unlimited_matches",
        "is_active",
        "created_at",
    ]
    list_filter = ["plan_type", "is_active", "is_ad_free", "unlimited_matches"]
    search_fields = ["name"]
    list_per_page = 50

    fieldsets = (
        (
            "기본 정보",
            {
                "fields": (
                    "name",
                    "plan_type",
                    "price",
                    "duration_days",
                )
            },
        ),
        (
            "프리미엄 혜택",
            {
                "fields": (
                    "is_ad_free",
                    "unlimited_matches",
                    "priority_matching",
                    "profile_boost",
                    "custom_badge",
                )
            },
        ),
        (
            "활성화",
            {
                "fields": ("is_active",)
            },
        ),
        ("타임스탬프", {"fields": ("created_at", "updated_at")}),
    )
    readonly_fields = ["created_at", "updated_at"]


@admin.register(UserSubscription)
class UserSubscriptionAdmin(admin.ModelAdmin):
    """사용자 구독 관리"""

    list_display = [
        "id",
        "user",
        "subscription",
        "status",
        "start_date",
        "end_date",
        "auto_renew",
        "created_at",
    ]
    list_filter = ["status", "auto_renew", "subscription__plan_type"]
    search_fields = ["user__nickname", "user__email"]
    readonly_fields = ["created_at", "updated_at"]
    list_per_page = 50

    fieldsets = (
        (
            "사용자 및 플랜",
            {
                "fields": (
                    "user",
                    "subscription",
                )
            },
        ),
        (
            "구독 기간",
            {
                "fields": (
                    "start_date",
                    "end_date",
                )
            },
        ),
        (
            "상태 및 설정",
            {
                "fields": (
                    "status",
                    "auto_renew",
                )
            },
        ),
        ("타임스탬프", {"fields": ("created_at", "updated_at")}),
    )


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    """결제 내역 관리"""

    list_display = [
        "id",
        "user",
        "amount",
        "currency",
        "payment_method",
        "status",
        "pg_provider",
        "created_at",
    ]
    list_filter = ["status", "payment_method", "pg_provider", "created_at"]
    search_fields = [
        "user__nickname",
        "user__email",
        "transaction_id",
    ]
    readonly_fields = ["transaction_id", "created_at", "updated_at", "refunded_at"]
    list_per_page = 50

    fieldsets = (
        (
            "사용자 정보",
            {
                "fields": (
                    "user",
                    "user_subscription",
                )
            },
        ),
        (
            "결제 정보",
            {
                "fields": (
                    "payment_method",
                    "amount",
                    "currency",
                    "status",
                )
            },
        ),
        (
            "외부 시스템 정보",
            {
                "fields": (
                    "transaction_id",
                    "pg_provider",
                    "receipt_url",
                )
            },
        ),
        (
            "환불 정보",
            {
                "fields": (
                    "refunded_at",
                    "refund_reason",
                )
            },
        ),
        ("타임스탬프", {"fields": ("created_at", "updated_at")}),
    )


@admin.register(Advertisement)
class AdvertisementAdmin(admin.ModelAdmin):
    """광고 관리"""

    list_display = [
        "id",
        "advertiser_name",
        "title",
        "ad_type",
        "status",
        "start_date",
        "end_date",
        "total_impressions",
        "total_clicks",
        "get_ctr",
        "created_at",
    ]
    list_filter = ["status", "ad_type", "start_date", "end_date"]
    search_fields = ["advertiser_name", "advertiser_email", "title"]
    readonly_fields = [
        "total_impressions",
        "total_clicks",
        "get_ctr",
        "created_at",
        "updated_at",
    ]
    list_per_page = 50

    fieldsets = (
        (
            "광고주 정보",
            {
                "fields": (
                    "advertiser_name",
                    "advertiser_email",
                )
            },
        ),
        (
            "광고 내용",
            {
                "fields": (
                    "title",
                    "description",
                    "ad_type",
                )
            },
        ),
        (
            "광고 소재",
            {
                "fields": (
                    "image_url",
                    "video_url",
                    "link_url",
                )
            },
        ),
        (
            "광고 기간",
            {
                "fields": (
                    "start_date",
                    "end_date",
                )
            },
        ),
        (
            "타겟팅",
            {
                "fields": (
                    "target_countries",
                    "target_age_min",
                    "target_age_max",
                )
            },
        ),
        (
            "예산 및 성과",
            {
                "fields": (
                    "budget",
                    "cost_per_click",
                    "total_impressions",
                    "total_clicks",
                    "get_ctr",
                )
            },
        ),
        (
            "상태",
            {
                "fields": ("status",)
            },
        ),
        ("타임스탬프", {"fields": ("created_at", "updated_at")}),
    )

    def get_ctr(self, obj):
        """CTR 표시"""
        return f"{obj.get_ctr():.2f}%"

    get_ctr.short_description = "CTR"


@admin.register(AdImpression)
class AdImpressionAdmin(admin.ModelAdmin):
    """광고 노출 기록 관리"""

    list_display = [
        "id",
        "advertisement",
        "user",
        "action_type",
        "created_at",
    ]
    list_filter = ["action_type", "created_at"]
    search_fields = [
        "advertisement__title",
        "user__nickname",
        "user__email",
    ]
    readonly_fields = ["advertisement", "user", "action_type", "created_at"]
    list_per_page = 100

    fieldsets = (
        (
            "광고 정보",
            {
                "fields": ("advertisement",)
            },
        ),
        (
            "사용자 정보",
            {
                "fields": ("user",)
            },
        ),
        (
            "액션 정보",
            {
                "fields": ("action_type",)
            },
        ),
        ("타임스탬프", {"fields": ("created_at",)}),
    )

    def has_add_permission(self, request):
        """관리자 페이지에서 직접 추가 불가"""
        return False

    def has_delete_permission(self, request, obj=None):
        """삭제 불가 (분석용 데이터)"""
        return False

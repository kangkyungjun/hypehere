from rest_framework import serializers
from accounts.serializers import UserSerializer
from .models import Subscription, UserSubscription, Payment, Advertisement, AdImpression


class SubscriptionSerializer(serializers.ModelSerializer):
    """구독 플랜 Serializer"""

    class Meta:
        model = Subscription
        fields = [
            "id",
            "name",
            "plan_type",
            "price",
            "duration_days",
            "is_ad_free",
            "unlimited_matches",
            "priority_matching",
            "profile_boost",
            "custom_badge",
            "is_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
            "updated_at",
        ]


class UserSubscriptionSerializer(serializers.ModelSerializer):
    """사용자 구독 Serializer"""

    user = UserSerializer(read_only=True)
    subscription = SubscriptionSerializer(read_only=True)
    is_valid = serializers.SerializerMethodField()
    is_expired = serializers.SerializerMethodField()

    class Meta:
        model = UserSubscription
        fields = [
            "id",
            "user",
            "subscription",
            "start_date",
            "end_date",
            "status",
            "auto_renew",
            "is_valid",
            "is_expired",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "user",
            "start_date",
            "end_date",
            "status",
            "created_at",
            "updated_at",
        ]

    def get_is_valid(self, obj):
        """구독 유효 여부"""
        return obj.is_valid()

    def get_is_expired(self, obj):
        """구독 만료 여부"""
        return obj.is_expired()


class PaymentSerializer(serializers.ModelSerializer):
    """결제 내역 Serializer"""

    user = UserSerializer(read_only=True)

    class Meta:
        model = Payment
        fields = [
            "id",
            "user",
            "user_subscription",
            "payment_method",
            "amount",
            "currency",
            "status",
            "transaction_id",
            "pg_provider",
            "receipt_url",
            "refunded_at",
            "refund_reason",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "user",
            "transaction_id",
            "status",
            "refunded_at",
            "refund_reason",
            "created_at",
            "updated_at",
        ]


class AdvertisementSerializer(serializers.ModelSerializer):
    """광고 Serializer"""

    ctr = serializers.SerializerMethodField()
    is_active_now = serializers.SerializerMethodField()

    class Meta:
        model = Advertisement
        fields = [
            "id",
            "advertiser_name",
            "title",
            "description",
            "ad_type",
            "image_url",
            "video_url",
            "link_url",
            "start_date",
            "end_date",
            "target_countries",
            "target_age_min",
            "target_age_max",
            "total_impressions",
            "total_clicks",
            "ctr",
            "status",
            "is_active_now",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "total_impressions",
            "total_clicks",
            "created_at",
            "updated_at",
        ]

    def get_ctr(self, obj):
        """CTR 계산"""
        return obj.get_ctr()

    def get_is_active_now(self, obj):
        """현재 활성 상태 여부"""
        return obj.is_active()


class AdImpressionSerializer(serializers.ModelSerializer):
    """광고 노출 기록 Serializer"""

    user = UserSerializer(read_only=True)
    advertisement = AdvertisementSerializer(read_only=True)

    class Meta:
        model = AdImpression
        fields = [
            "id",
            "advertisement",
            "user",
            "action_type",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "advertisement",
            "user",
            "action_type",
            "created_at",
        ]

from rest_framework import status, generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.utils import timezone
from datetime import timedelta
import uuid

from accounts.permissions import IsUser
from .models import Subscription, UserSubscription, Payment, Advertisement, AdImpression
from .serializers import (
    SubscriptionSerializer,
    UserSubscriptionSerializer,
    PaymentSerializer,
    AdvertisementSerializer,
    AdImpressionSerializer,
)


# ============================================================================
# 구독 플랜 API Views
# ============================================================================


class SubscriptionListAPIView(generics.ListAPIView):
    """구독 플랜 목록 조회 API"""

    serializer_class = SubscriptionSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        return Subscription.objects.filter(is_active=True).order_by("price")


class SubscriptionDetailAPIView(generics.RetrieveAPIView):
    """구독 플랜 상세 조회 API"""

    serializer_class = SubscriptionSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        return Subscription.objects.filter(is_active=True)


# ============================================================================
# 사용자 구독 API Views
# ============================================================================


class UserSubscriptionListAPIView(generics.ListAPIView):
    """내 구독 목록 조회 API"""

    serializer_class = UserSubscriptionSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        return UserSubscription.objects.filter(user=self.request.user).select_related(
            "subscription"
        )


class UserSubscriptionPurchaseAPIView(APIView):
    """구독 구매 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def post(self, request):
        subscription_id = request.data.get("subscription_id")
        payment_method = request.data.get("payment_method")

        if not all([subscription_id, payment_method]):
            return Response(
                {"error": "필수 정보를 모두 입력해주세요."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 구독 플랜 확인
        subscription = get_object_or_404(
            Subscription, id=subscription_id, is_active=True
        )

        # 이미 활성 구독이 있는지 확인
        active_subscription = UserSubscription.objects.filter(
            user=request.user, status=UserSubscription.Status.ACTIVE
        ).first()

        if active_subscription and active_subscription.is_valid():
            return Response(
                {"error": "이미 활성화된 구독이 있습니다."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 결제 시작 (실제로는 PG사 API 호출)
        transaction_id = f"TXN-{uuid.uuid4()}"

        # 결제 기록 생성
        payment = Payment.objects.create(
            user=request.user,
            payment_method=payment_method,
            amount=subscription.price,
            transaction_id=transaction_id,
            pg_provider="test",  # 실제로는 PG사 이름
            status=Payment.Status.PENDING,
        )

        # 사용자 구독 생성
        start_date = timezone.now()
        end_date = start_date + timedelta(days=subscription.duration_days)

        user_subscription = UserSubscription.objects.create(
            user=request.user,
            subscription=subscription,
            start_date=start_date,
            end_date=end_date,
            status=UserSubscription.Status.ACTIVE,
        )

        # 결제와 구독 연결
        payment.user_subscription = user_subscription
        payment.complete()  # 테스트 환경에서는 즉시 완료

        serializer = UserSubscriptionSerializer(user_subscription)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class UserSubscriptionCancelAPIView(APIView):
    """구독 취소 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def post(self, request, pk):
        # 본인의 구독만 취소 가능
        user_subscription = get_object_or_404(
            UserSubscription, pk=pk, user=request.user
        )

        # 이미 취소되었거나 만료된 경우
        if user_subscription.status != UserSubscription.Status.ACTIVE:
            return Response(
                {"error": "취소할 수 없는 구독입니다."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 구독 취소
        user_subscription.cancel()

        return Response(
            {"message": "구독이 취소되었습니다."},
            status=status.HTTP_200_OK,
        )


class UserSubscriptionRenewAPIView(APIView):
    """구독 갱신 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def post(self, request, pk):
        # 본인의 구독만 갱신 가능
        user_subscription = get_object_or_404(
            UserSubscription, pk=pk, user=request.user
        )

        # 갱신 시도
        if user_subscription.renew():
            # 결제 생성 (실제로는 PG사 API 호출)
            transaction_id = f"TXN-{uuid.uuid4()}"

            Payment.objects.create(
                user=request.user,
                user_subscription=user_subscription,
                payment_method=Payment.PaymentMethod.CARD,  # 실제로는 저장된 결제수단 사용
                amount=user_subscription.subscription.price,
                transaction_id=transaction_id,
                pg_provider="test",
                status=Payment.Status.COMPLETED,
            )

            return Response(
                {"message": "구독이 갱신되었습니다."},
                status=status.HTTP_200_OK,
            )
        else:
            return Response(
                {"error": "갱신할 수 없는 구독입니다."},
                status=status.HTTP_400_BAD_REQUEST,
            )


# ============================================================================
# 결제 내역 API Views
# ============================================================================


class PaymentListAPIView(generics.ListAPIView):
    """결제 내역 조회 API"""

    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        return Payment.objects.filter(user=self.request.user).select_related(
            "user_subscription"
        )


class PaymentDetailAPIView(generics.RetrieveAPIView):
    """결제 상세 조회 API"""

    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        # 본인의 결제 내역만 조회 가능
        return Payment.objects.filter(user=self.request.user).select_related(
            "user_subscription"
        )


# ============================================================================
# 광고 API Views
# ============================================================================


class AdvertisementAPIView(APIView):
    """광고 조회 API (무료 사용자)"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get(self, request):
        # 프리미엄 사용자는 광고 표시 안함
        active_subscription = UserSubscription.objects.filter(
            user=request.user, status=UserSubscription.Status.ACTIVE
        ).first()

        if active_subscription and active_subscription.is_valid():
            if active_subscription.subscription.is_ad_free:
                return Response(
                    {"message": "프리미엄 사용자는 광고가 표시되지 않습니다."},
                    status=status.HTTP_200_OK,
                )

        # 사용자에게 맞는 광고 찾기
        user = request.user
        now = timezone.now()

        # 타겟팅 조건에 맞는 활성 광고 찾기
        advertisements = Advertisement.objects.filter(
            status=Advertisement.Status.ACTIVE,
            start_date__lte=now,
            end_date__gte=now,
        )

        # 국가 필터링
        if user.country:
            advertisements = advertisements.filter(
                target_countries__contains=[user.country.code]
            )

        # 연령 필터링
        if user.birth_date:
            age = (timezone.now().date() - user.birth_date).days // 365
            advertisements = advertisements.filter(
                target_age_min__lte=age, target_age_max__gte=age
            )

        # 랜덤으로 1개 선택
        advertisement = advertisements.order_by("?").first()

        if not advertisement:
            return Response(
                {"message": "표시할 광고가 없습니다."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # 노출 기록 생성
        AdImpression.objects.create(
            advertisement=advertisement,
            user=request.user,
            action_type=AdImpression.ActionType.IMPRESSION,
        )

        # 노출 수 증가
        advertisement.increment_impression()

        serializer = AdvertisementSerializer(advertisement)
        return Response(serializer.data, status=status.HTTP_200_OK)


class AdvertisementClickAPIView(APIView):
    """광고 클릭 기록 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def post(self, request, pk):
        advertisement = get_object_or_404(Advertisement, pk=pk)

        # 클릭 기록 생성
        AdImpression.objects.create(
            advertisement=advertisement,
            user=request.user,
            action_type=AdImpression.ActionType.CLICK,
        )

        # 클릭 수 증가
        advertisement.increment_click()

        return Response(
            {"message": "광고 클릭이 기록되었습니다.", "link_url": advertisement.link_url},
            status=status.HTTP_200_OK,
        )

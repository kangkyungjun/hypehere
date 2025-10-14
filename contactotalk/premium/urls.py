from django.urls import path
from .views import (
    # 구독 플랜
    SubscriptionListAPIView,
    SubscriptionDetailAPIView,
    # 사용자 구독
    UserSubscriptionListAPIView,
    UserSubscriptionPurchaseAPIView,
    UserSubscriptionCancelAPIView,
    UserSubscriptionRenewAPIView,
    # 결제 내역
    PaymentListAPIView,
    PaymentDetailAPIView,
    # 광고
    AdvertisementAPIView,
    AdvertisementClickAPIView,
)

app_name = "premium"

urlpatterns = [
    # 구독 플랜
    path("subscriptions/", SubscriptionListAPIView.as_view(), name="subscription_list"),
    path("subscriptions/<int:pk>/", SubscriptionDetailAPIView.as_view(), name="subscription_detail"),

    # 사용자 구독
    path("my-subscriptions/", UserSubscriptionListAPIView.as_view(), name="my_subscription_list"),
    path("my-subscriptions/purchase/", UserSubscriptionPurchaseAPIView.as_view(), name="subscription_purchase"),
    path("my-subscriptions/<int:pk>/cancel/", UserSubscriptionCancelAPIView.as_view(), name="subscription_cancel"),
    path("my-subscriptions/<int:pk>/renew/", UserSubscriptionRenewAPIView.as_view(), name="subscription_renew"),

    # 결제 내역
    path("payments/", PaymentListAPIView.as_view(), name="payment_list"),
    path("payments/<int:pk>/", PaymentDetailAPIView.as_view(), name="payment_detail"),

    # 광고
    path("advertisements/", AdvertisementAPIView.as_view(), name="advertisement"),
    path("advertisements/<int:pk>/click/", AdvertisementClickAPIView.as_view(), name="advertisement_click"),
]

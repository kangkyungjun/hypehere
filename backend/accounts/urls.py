from django.urls import path
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    TokenVerifyView,
)
from .views import (
    register_view,
    register_with_verification_view,
    login_view,
    profile_view,
    update_profile_view,
    change_password_view,
    send_verification_code_view,
    verify_code_view,
    password_reset_request_view,
    password_reset_confirm_view,
    request_deletion_view,
    cancel_deletion_view,
    search_users_view,
    promote_to_gold_view,
    promote_to_manager_view,
    demote_to_regular_view,
    device_register_view,
    device_deactivate_view,
    device_subscriptions_view,
    broadcast_push_view,
    notification_history_view,
    notification_mark_read_view,
    notification_mark_single_read_view,
    revenuecat_webhook_view,
    subscription_status_view,
    investment_profile_view,
    user_recommendations_view,
    report_ad_failure_view,
)

app_name = 'accounts'

urlpatterns = [
    # Flutter 호환 인증 엔드포인트
    path('register/', register_view, name='register'),
    path('register-with-verification/', register_with_verification_view, name='register-with-verification'),
    path('login/', login_view, name='login'),
    path('profile/', profile_view, name='profile'),
    path('update/', update_profile_view, name='update-profile'),
    path('change-password/', change_password_view, name='change-password'),

    # 이메일 인증
    path('verification/send/', send_verification_code_view, name='verification-send'),
    path('verification/verify/', verify_code_view, name='verification-verify'),

    # 비밀번호 재설정
    path('password-reset/request/', password_reset_request_view, name='password-reset-request'),
    path('password-reset/confirm/', password_reset_confirm_view, name='password-reset-confirm'),

    # 회원탈퇴
    path('request-deletion/', request_deletion_view, name='request-deletion'),
    path('cancel-deletion/', cancel_deletion_view, name='cancel-deletion'),

    # 권한 관리 (Manager/Master 전용)
    path('users/search/', search_users_view, name='user-search'),
    path('users/<int:pk>/promote-to-gold/', promote_to_gold_view, name='promote-to-gold'),
    path('users/<int:pk>/promote-to-manager/', promote_to_manager_view, name='promote-to-manager'),
    path('users/<int:pk>/demote-to-regular/', demote_to_regular_view, name='demote-to-regular'),

    # FCM 디바이스 토큰
    path('device/register/', device_register_view, name='device-register'),
    path('device/deactivate/', device_deactivate_view, name='device-deactivate'),
    path('device/subscriptions/', device_subscriptions_view, name='device-subscriptions'),

    # 푸시 알림 브로드캐스트 (Manager+ 전용)
    path('push/broadcast/', broadcast_push_view, name='push-broadcast'),

    # 알림 인박스
    path('notifications/', notification_history_view, name='notification-history'),
    path('notifications/read/', notification_mark_read_view, name='notification-mark-read'),
    path('notifications/<int:pk>/read/', notification_mark_single_read_view, name='notification-mark-single-read'),

    # 투자 프로필
    path('investment-profile/', investment_profile_view, name='investment-profile'),

    # 추천종목 (Phase C) — 앱 조회. GET /api/marketlens/accounts/recommendations/?date=...
    path('recommendations/', user_recommendations_view, name='user-recommendations'),

    # RevenueCat IAP Webhook + 구독 상태
    path('webhook/revenuecat/', revenuecat_webhook_view, name='revenuecat-webhook'),
    path('subscription/status/', subscription_status_view, name='subscription-status'),

    # 운영 알림 — 광고 로드 실패 보고 (클라이언트 → owner/매니저 통지)
    path('ops/ad-failure/', report_ad_failure_view, name='ops-ad-failure'),

    # JWT 엔드포인트 (하위 호환)
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('token/verify/', TokenVerifyView.as_view(), name='token_verify'),
]

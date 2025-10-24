from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    RegisterAPIView,
    LoginAPIView,
    LogoutAPIView,
    ProfileAPIView,
    ProfileUpdateAPIView,
    ChangePasswordAPIView,
    InterestListAPIView,
    UserDetailAPIView,
    UserStatsAPIView,
    check_match_limit,
    health_check,
)

app_name = "accounts"

urlpatterns = [
    # 헬스 체크
    path("health/", health_check, name="health_check"),

    # 인증
    path("register/", RegisterAPIView.as_view(), name="register"),
    path("login/", LoginAPIView.as_view(), name="login"),
    path("logout/", LogoutAPIView.as_view(), name="logout"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),

    # 프로필
    path("profile/", ProfileAPIView.as_view(), name="profile"),
    path("profile/update/", ProfileUpdateAPIView.as_view(), name="profile_update"),
    path("profile/password/", ChangePasswordAPIView.as_view(), name="change_password"),

    # 사용자
    path("users/<int:id>/", UserDetailAPIView.as_view(), name="user_detail"),

    # 통계
    path("stats/", UserStatsAPIView.as_view(), name="user_stats"),

    # 관심사
    path("interests/", InterestListAPIView.as_view(), name="interest_list"),

    # 매칭
    path("match/check/", check_match_limit, name="check_match_limit"),
]

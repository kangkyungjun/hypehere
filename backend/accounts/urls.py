from django.urls import path
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    TokenVerifyView,
)
from .views import (
    register_view,
    login_view,
    profile_view,
    update_profile_view,
    change_password_view,
    search_users_view,
    promote_to_gold_view,
    promote_to_manager_view,
)

app_name = 'accounts'

urlpatterns = [
    # Flutter 호환 인증 엔드포인트
    path('register/', register_view, name='register'),
    path('login/', login_view, name='login'),
    path('profile/', profile_view, name='profile'),
    path('update/', update_profile_view, name='update-profile'),
    path('change-password/', change_password_view, name='change-password'),

    # 권한 관리 (Manager/Master 전용)
    path('users/search/', search_users_view, name='user-search'),
    path('users/<int:pk>/promote-to-gold/', promote_to_gold_view, name='promote-to-gold'),
    path('users/<int:pk>/promote-to-manager/', promote_to_manager_view, name='promote-to-manager'),

    # JWT 엔드포인트 (하위 호환)
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('token/verify/', TokenVerifyView.as_view(), name='token_verify'),
]

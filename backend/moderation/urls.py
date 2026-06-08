from django.urls import path

from .views import (
    block_user_view,
    unblock_user_view,
    blocked_users_view,
)

app_name = 'moderation'

urlpatterns = [
    path('users/blocked/', blocked_users_view, name='blocked-users'),
    path('users/<int:user_id>/block/', block_user_view, name='block-user'),
    # DELETE 같은 경로로 차단 해제
    path('users/<int:user_id>/unblock/', unblock_user_view, name='unblock-user'),
]

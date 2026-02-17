from django.urls import path
from .views import (
    UserRegistrationView,
    UserLoginView,
    UserLogoutView,
    UserProfileView,
    UserUpdateView,
    PasswordChangeView,
    UserDeleteView,
    UserPostsAPIView,
    UserPostsSearchAPIView,
    CombinedSearchAPIView,
    FollowUserView,
    UnfollowUserView,
    FollowStatusView,
    FollowersListView,
    FollowingListView,
    PrivacySettingsView,
    BlockUserView,
    UnblockUserView,
    BlockedUsersListView,
    AccountStatusView,
    DeactivateAccountView,
    ReactivateAccountView,
    RequestAccountDeletionView,
    CancelAccountDeletionView,
    UserSearchAPIView,
    PromoteToGoldAPIView,
    PromoteToManagerAPIView,
    DemoteToRegularAPIView,
)

app_name = 'accounts_api'

urlpatterns = [
    # Authentication endpoints
    path('register/', UserRegistrationView.as_view(), name='register'),
    path('login/', UserLoginView.as_view(), name='login'),
    path('logout/', UserLogoutView.as_view(), name='logout'),

    # User profile endpoints
    path('profile/', UserProfileView.as_view(), name='profile'),
    path('update/', UserUpdateView.as_view(), name='update'),

    # Password management
    path('change-password/', PasswordChangeView.as_view(), name='change-password'),

    # Account management
    path('delete/', UserDeleteView.as_view(), name='delete'),

    # Search
    path('search/combined/', CombinedSearchAPIView.as_view(), name='combined_search'),

    # Follow endpoints
    path('<str:username>/follow/', FollowUserView.as_view(), name='follow_user'),
    path('<str:username>/unfollow/', UnfollowUserView.as_view(), name='unfollow_user'),
    path('<str:username>/follow-status/', FollowStatusView.as_view(), name='follow_status'),
    path('<str:username>/followers/', FollowersListView.as_view(), name='followers_list'),
    path('<str:username>/following/', FollowingListView.as_view(), name='following_list'),

    # Privacy & Block endpoints
    path('privacy-settings/', PrivacySettingsView.as_view(), name='privacy_settings'),
    path('<str:username>/block/', BlockUserView.as_view(), name='block_user'),
    path('<str:username>/unblock/', UnblockUserView.as_view(), name='unblock_user'),
    path('blocked-users/', BlockedUsersListView.as_view(), name='blocked_users'),

    # Account Management endpoints
    path('account-status/', AccountStatusView.as_view(), name='account_status'),
    path('deactivate/', DeactivateAccountView.as_view(), name='deactivate'),
    path('reactivate/', ReactivateAccountView.as_view(), name='reactivate'),
    path('request-deletion/', RequestAccountDeletionView.as_view(), name='request_deletion'),
    path('cancel-deletion/', CancelAccountDeletionView.as_view(), name='cancel_deletion'),

    # User posts
    path('<str:username>/posts/', UserPostsAPIView.as_view(), name='user_posts'),
    path('<str:username>/posts/search/', UserPostsSearchAPIView.as_view(), name='user_posts_search'),

    # MarketLens Admin Management (Flutter app)
    path('users/search/', UserSearchAPIView.as_view(), name='api_user_search'),
    path('users/<int:user_id>/promote-to-gold/', PromoteToGoldAPIView.as_view(), name='api_promote_to_gold'),
    path('users/<int:user_id>/promote-to-manager/', PromoteToManagerAPIView.as_view(), name='api_promote_to_manager'),
    path('users/<int:user_id>/demote-to-regular/', DemoteToRegularAPIView.as_view(), name='api_demote_to_regular'),
]

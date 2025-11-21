from django.urls import path
from .views import (
    LoginTemplateView,
    LogoutTemplateView,
    RegisterTemplateView,
    ProfileTemplateView,
    ProfileUpdateTemplateView,
    SettingsTemplateView,
    NotificationSettingsTemplateView,
    FollowersListTemplateView,
    FollowingListTemplateView,
    PrivacySettingsTemplateView,
    BlockedUsersListTemplateView,
    AccountManagementTemplateView,
    FavoritesTemplateView,
    ReportHistoryTemplateView,
    ReportListAPIView,
    ReportDeleteAPIView,
    ReportDismissAPIView,
    UserFavoritesAPIView,
    SupportTicketListView,
    SupportTicketCreateView,
    SupportTicketDetailView,
    SupportTicketRespondView,
    SuspendUserAPIView,
    LiftSuspensionAPIView,
    BanUserAPIView,
    UnbanUserAPIView,
)

app_name = 'accounts'

urlpatterns = [
    # HTML Template Views
    path('register/', RegisterTemplateView.as_view(), name='register'),
    path('login/', LoginTemplateView.as_view(), name='login'),
    path('logout/', LogoutTemplateView.as_view(), name='logout'),
    path('profile/', ProfileTemplateView.as_view(), name='profile'),
    path('profile/<str:username>/', ProfileTemplateView.as_view(), name='profile_detail'),
    path('profile/<str:username>/followers/', FollowersListTemplateView.as_view(), name='followers_list'),
    path('profile/<str:username>/following/', FollowingListTemplateView.as_view(), name='following_list'),
    path('update/', ProfileUpdateTemplateView.as_view(), name='update'),
    path('settings/', SettingsTemplateView.as_view(), name='settings'),
    path('settings/notifications/', NotificationSettingsTemplateView.as_view(), name='notification_settings'),
    path('settings/privacy/', PrivacySettingsTemplateView.as_view(), name='privacy_settings'),
    path('settings/blocked-users/', BlockedUsersListTemplateView.as_view(), name='blocked_users'),
    path('settings/account-management/', AccountManagementTemplateView.as_view(), name='account_management'),
    path('favorites/', FavoritesTemplateView.as_view(), name='favorites'),
    path('reports/', ReportHistoryTemplateView.as_view(), name='report_history'),

    # Support Ticket Views
    path('support/', SupportTicketListView.as_view(), name='support_list'),
    path('support/create/', SupportTicketCreateView.as_view(), name='support_create'),
    path('support/<int:pk>/', SupportTicketDetailView.as_view(), name='support_detail'),
    path('support/<int:pk>/respond/', SupportTicketRespondView.as_view(), name='support_respond'),

    # API Views
    path('api/favorites/', UserFavoritesAPIView.as_view(), name='user_favorites_api'),
    path('api/reports/list/', ReportListAPIView.as_view(), name='report_list_api'),
    path('api/reports/<int:report_id>/delete/', ReportDeleteAPIView.as_view(), name='report_delete_api'),
    path('api/reports/<int:report_id>/dismiss/', ReportDismissAPIView.as_view(), name='report_dismiss_api'),

    # Admin Action API Views
    path('api/admin/<str:username>/suspend/', SuspendUserAPIView.as_view(), name='admin_suspend_user'),
    path('api/admin/<str:username>/lift-suspension/', LiftSuspensionAPIView.as_view(), name='admin_lift_suspension'),
    path('api/admin/<str:username>/ban/', BanUserAPIView.as_view(), name='admin_ban_user'),
    path('api/admin/<str:username>/unban/', UnbanUserAPIView.as_view(), name='admin_unban_user'),
]

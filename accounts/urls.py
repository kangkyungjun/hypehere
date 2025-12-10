from django.urls import path
from .views import (
    LoginTemplateView,
    LogoutTemplateView,
    RegisterTemplateView,
    ProfileTemplateView,
    ProfileUpdateTemplateView,
    SettingsTemplateView,
    AdminPanelView,
    NotificationSettingsTemplateView,
    FollowersListTemplateView,
    FollowingListTemplateView,
    PrivacySettingsTemplateView,
    BlockedUsersListTemplateView,
    AccountManagementTemplateView,
    TermsOfServiceView,
    PrivacyPolicyView,
    CookiePolicyView,
    CommunityGuidelinesView,
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
    password_reset_request_view,
    PasswordResetRequestAPIView,
    ProfilePictureDeleteView,
    UserReportCreateView,
    LegalDocumentListView,
    LegalDocumentEditView,
    LegalDocumentSaveView,
    LegalDocumentVersionListView,
)

app_name = 'accounts'

urlpatterns = [
    # HTML Template Views
    path('register/', RegisterTemplateView.as_view(), name='register'),
    path('login/', LoginTemplateView.as_view(), name='login'),
    path('logout/', LogoutTemplateView.as_view(), name='logout'),
    path('password-reset/', password_reset_request_view, name='password_reset'),
    path('terms/', TermsOfServiceView.as_view(), name='terms_of_service'),
    path('terms/', TermsOfServiceView.as_view(), name='terms'),
    path('privacy/', PrivacyPolicyView.as_view(), name='privacy_policy'),
    path('privacy/', PrivacyPolicyView.as_view(), name='privacy'),
    path('cookies/', CookiePolicyView.as_view(), name='cookie_policy'),
    path('cookies/', CookiePolicyView.as_view(), name='cookies'),
    path('community-guidelines/', CommunityGuidelinesView.as_view(), name='community_guidelines'),

    # Simplified Legal Document Edit URLs
    path('legal/<str:document_type>/edit/', LegalDocumentEditView.as_view(), name='legal_document_edit_simple'),
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
    path('admin-panel/', AdminPanelView.as_view(), name='admin_panel'),

    # Legal Document Management URLs (Prime/Superuser only)
    path('admin-panel/legal-documents/', LegalDocumentListView.as_view(), name='legal_document_list'),
    path('admin-panel/legal-documents/<str:document_type>/<str:language>/edit/', LegalDocumentEditView.as_view(), name='legal_document_edit'),
    path('admin-panel/legal-documents/<str:document_type>/<str:language>/save/', LegalDocumentSaveView.as_view(), name='legal_document_save'),
    path('admin-panel/legal-documents/<str:document_type>/<str:language>/versions/', LegalDocumentVersionListView.as_view(), name='legal_document_versions'),

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

    # Password Reset API
    path('api/password-reset/', PasswordResetRequestAPIView.as_view(), name='password_reset_api'),

    # Profile Picture API
    path('api/profile-picture/', ProfilePictureDeleteView.as_view(), name='profile_picture_delete'),

    # User Report API
    path('api/users/report/', UserReportCreateView.as_view(), name='user_report_create'),
]

from django.urls import path
from .views import (
    # 신고
    ReportCreateAPIView,
    ReportListAPIView,
    ReportDetailAPIView,
    # 관리자 신고 관리
    AdminReportListAPIView,
    AdminReportDetailAPIView,
    AdminReportReviewAPIView,
    AdminReportResolveAPIView,
    AdminReportRejectAPIView,
    # 제재
    AdminSanctionCreateAPIView,
    AdminSanctionListAPIView,
    AdminSanctionRemoveAPIView,
    # 로그
    AdminModerationLogListAPIView,
    # 통계
    AdminModerationStatsAPIView,
)

app_name = "moderation"

urlpatterns = [
    # 신고 (일반 사용자)
    path("reports/", ReportListAPIView.as_view(), name="report_list"),
    path("reports/create/", ReportCreateAPIView.as_view(), name="report_create"),
    path("reports/<int:pk>/", ReportDetailAPIView.as_view(), name="report_detail"),

    # 관리자 신고 관리
    path("admin/reports/", AdminReportListAPIView.as_view(), name="admin_report_list"),
    path("admin/reports/<int:pk>/", AdminReportDetailAPIView.as_view(), name="admin_report_detail"),
    path("admin/reports/<int:pk>/review/", AdminReportReviewAPIView.as_view(), name="admin_report_review"),
    path("admin/reports/<int:pk>/resolve/", AdminReportResolveAPIView.as_view(), name="admin_report_resolve"),
    path("admin/reports/<int:pk>/reject/", AdminReportRejectAPIView.as_view(), name="admin_report_reject"),

    # 제재 관리
    path("admin/sanctions/", AdminSanctionListAPIView.as_view(), name="admin_sanction_list"),
    path("admin/sanctions/create/", AdminSanctionCreateAPIView.as_view(), name="admin_sanction_create"),
    path("admin/sanctions/<int:pk>/remove/", AdminSanctionRemoveAPIView.as_view(), name="admin_sanction_remove"),

    # 관리 로그
    path("admin/logs/", AdminModerationLogListAPIView.as_view(), name="admin_log_list"),

    # 관리 통계
    path("admin/stats/", AdminModerationStatsAPIView.as_view(), name="admin_stats"),
]

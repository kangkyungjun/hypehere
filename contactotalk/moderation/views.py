from rest_framework import status, generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.db.models import Q, Count
from django.utils import timezone

from accounts.permissions import IsUser, IsManager
from .models import Report, UserSanction, ModerationLog
from .serializers import (
    ReportSerializer,
    ReportCreateSerializer,
    UserSanctionSerializer,
    ModerationLogSerializer,
    ModerationStatsSerializer,
)


# ============================================================================
# 신고 API Views
# ============================================================================


class ReportCreateAPIView(generics.CreateAPIView):
    """신고 작성 API"""

    serializer_class = ReportCreateSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def perform_create(self, serializer):
        """신고 생성"""
        serializer.save()


class ReportListAPIView(generics.ListAPIView):
    """신고 목록 조회 API"""

    serializer_class = ReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        user = self.request.user

        # 본인이 신고한 내역만 조회
        queryset = Report.objects.filter(reporter=user).select_related(
            "reporter", "reviewer"
        )

        # 필터링: 상태
        report_status = self.request.query_params.get("status")
        if report_status:
            queryset = queryset.filter(status=report_status)

        return queryset.order_by("-created_at")


class ReportDetailAPIView(generics.RetrieveAPIView):
    """신고 상세 조회 API"""

    serializer_class = ReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        # 본인이 신고한 내역만 조회 가능
        return Report.objects.filter(reporter=self.request.user).select_related(
            "reporter", "reviewer"
        )


# ============================================================================
# 관리자 신고 관리 API Views
# ============================================================================


class AdminReportListAPIView(generics.ListAPIView):
    """관리자 신고 목록 조회 API"""

    serializer_class = ReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsManager]

    def get_queryset(self):
        queryset = Report.objects.all().select_related("reporter", "reviewer")

        # 필터링: 상태
        report_status = self.request.query_params.get("status")
        if report_status:
            queryset = queryset.filter(status=report_status)

        # 필터링: 타입
        report_type = self.request.query_params.get("type")
        if report_type:
            queryset = queryset.filter(report_type=report_type)

        # 필터링: 사유
        reason = self.request.query_params.get("reason")
        if reason:
            queryset = queryset.filter(reason=reason)

        return queryset.order_by("-created_at")


class AdminReportDetailAPIView(generics.RetrieveAPIView):
    """관리자 신고 상세 조회 API"""

    serializer_class = ReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsManager]
    queryset = Report.objects.all().select_related("reporter", "reviewer")


class AdminReportReviewAPIView(APIView):
    """신고 검토 시작 API (관리자)"""

    permission_classes = [permissions.IsAuthenticated, IsManager]

    def post(self, request, pk):
        report = get_object_or_404(Report, pk=pk)

        # 이미 검토 중이거나 처리 완료된 경우
        if report.status != Report.Status.PENDING:
            return Response(
                {"error": "이미 검토 중이거나 처리 완료된 신고입니다."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 검토 시작
        report.status = Report.Status.REVIEWING
        report.reviewer = request.user
        report.save(update_fields=["status", "reviewer", "updated_at"])

        # 로그 기록
        ModerationLog.objects.create(
            moderator=request.user,
            action_type=ModerationLog.ActionType.REVIEW_REPORT,
            description=f"신고 #{report.id} 검토 시작",
            content_type=report.content_type,
            object_id=report.object_id,
        )

        return Response(
            {"message": "신고 검토를 시작했습니다."},
            status=status.HTTP_200_OK,
        )


class AdminReportResolveAPIView(APIView):
    """신고 처리 API (관리자)"""

    permission_classes = [permissions.IsAuthenticated, IsManager]

    def post(self, request, pk):
        report = get_object_or_404(Report, pk=pk)
        resolution = request.data.get("resolution")

        if not resolution:
            return Response(
                {"error": "처리 결과를 입력해주세요."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 신고 처리
        report.resolve(reviewer=request.user, resolution=resolution)

        # 로그 기록
        ModerationLog.objects.create(
            moderator=request.user,
            action_type=ModerationLog.ActionType.RESOLVE_REPORT,
            description=f"신고 #{report.id} 처리 완료: {resolution}",
            content_type=report.content_type,
            object_id=report.object_id,
        )

        return Response(
            {"message": "신고가 처리되었습니다."},
            status=status.HTTP_200_OK,
        )


class AdminReportRejectAPIView(APIView):
    """신고 반려 API (관리자)"""

    permission_classes = [permissions.IsAuthenticated, IsManager]

    def post(self, request, pk):
        report = get_object_or_404(Report, pk=pk)
        resolution = request.data.get("resolution")

        if not resolution:
            return Response(
                {"error": "반려 사유를 입력해주세요."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 신고 반려
        report.reject(reviewer=request.user, resolution=resolution)

        # 로그 기록
        ModerationLog.objects.create(
            moderator=request.user,
            action_type=ModerationLog.ActionType.REJECT_REPORT,
            description=f"신고 #{report.id} 반려: {resolution}",
            content_type=report.content_type,
            object_id=report.object_id,
        )

        return Response(
            {"message": "신고가 반려되었습니다."},
            status=status.HTTP_200_OK,
        )


# ============================================================================
# 제재 관리 API Views
# ============================================================================


class AdminSanctionCreateAPIView(APIView):
    """사용자 제재 부여 API (관리자)"""

    permission_classes = [permissions.IsAuthenticated, IsManager]

    def post(self, request):
        from accounts.models import User

        user_id = request.data.get("user_id")
        sanction_type = request.data.get("sanction_type")
        reason = request.data.get("reason")
        end_date = request.data.get("end_date")  # 일시 정지의 경우 필요
        report_id = request.data.get("report_id")  # 관련 신고 ID (선택)

        # 검증
        if not all([user_id, sanction_type, reason]):
            return Response(
                {"error": "필수 정보를 모두 입력해주세요."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = get_object_or_404(User, id=user_id)

        # 일시 정지인데 종료일이 없는 경우
        if sanction_type == UserSanction.SanctionType.TEMP_BAN and not end_date:
            return Response(
                {"error": "일시 정지의 경우 종료일을 입력해주세요."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 제재 생성
        sanction = UserSanction.objects.create(
            user=user,
            sanction_type=sanction_type,
            reason=reason,
            end_date=end_date if sanction_type == UserSanction.SanctionType.TEMP_BAN else None,
            sanctioned_by=request.user,
            related_report_id=report_id if report_id else None,
        )

        # 로그 기록
        ModerationLog.objects.create(
            moderator=request.user,
            action_type=ModerationLog.ActionType.ISSUE_BAN,
            description=f"{user.nickname}님에게 {sanction.get_sanction_type_display()} 부여: {reason}",
        )

        serializer = UserSanctionSerializer(sanction)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class AdminSanctionListAPIView(generics.ListAPIView):
    """제재 목록 조회 API (관리자)"""

    serializer_class = UserSanctionSerializer
    permission_classes = [permissions.IsAuthenticated, IsManager]

    def get_queryset(self):
        queryset = UserSanction.objects.all().select_related(
            "user", "sanctioned_by", "related_report"
        )

        # 필터링: 제재 타입
        sanction_type = self.request.query_params.get("type")
        if sanction_type:
            queryset = queryset.filter(sanction_type=sanction_type)

        # 필터링: 활성화 여부
        is_active = self.request.query_params.get("active")
        if is_active is not None:
            queryset = queryset.filter(is_active=is_active.lower() == "true")

        # 필터링: 사용자
        user_id = self.request.query_params.get("user_id")
        if user_id:
            queryset = queryset.filter(user_id=user_id)

        return queryset.order_by("-created_at")


class AdminSanctionRemoveAPIView(APIView):
    """제재 해제 API (관리자)"""

    permission_classes = [permissions.IsAuthenticated, IsManager]

    def post(self, request, pk):
        sanction = get_object_or_404(UserSanction, pk=pk)

        # 제재 비활성화
        sanction.deactivate()

        # 로그 기록
        ModerationLog.objects.create(
            moderator=request.user,
            action_type=ModerationLog.ActionType.REMOVE_BAN,
            description=f"{sanction.user.nickname}님의 {sanction.get_sanction_type_display()} 해제",
        )

        return Response(
            {"message": "제재가 해제되었습니다."},
            status=status.HTTP_200_OK,
        )


# ============================================================================
# 관리 로그 API Views
# ============================================================================


class AdminModerationLogListAPIView(generics.ListAPIView):
    """관리 로그 목록 조회 API (관리자)"""

    serializer_class = ModerationLogSerializer
    permission_classes = [permissions.IsAuthenticated, IsManager]

    def get_queryset(self):
        queryset = ModerationLog.objects.all().select_related("moderator")

        # 필터링: 액션 타입
        action_type = self.request.query_params.get("action")
        if action_type:
            queryset = queryset.filter(action_type=action_type)

        # 필터링: 관리자
        moderator_id = self.request.query_params.get("moderator_id")
        if moderator_id:
            queryset = queryset.filter(moderator_id=moderator_id)

        return queryset.order_by("-created_at")


# ============================================================================
# 관리 통계 API Views
# ============================================================================


class AdminModerationStatsAPIView(APIView):
    """관리 통계 API (관리자)"""

    permission_classes = [permissions.IsAuthenticated, IsManager]

    def get(self, request):
        # 신고 통계
        total_reports = Report.objects.count()
        pending_reports = Report.objects.filter(status=Report.Status.PENDING).count()
        reviewing_reports = Report.objects.filter(
            status=Report.Status.REVIEWING
        ).count()
        resolved_reports = Report.objects.filter(status=Report.Status.RESOLVED).count()
        rejected_reports = Report.objects.filter(status=Report.Status.REJECTED).count()

        # 제재 통계
        total_sanctions = UserSanction.objects.count()
        active_sanctions = UserSanction.objects.filter(is_active=True).count()
        warnings = UserSanction.objects.filter(
            sanction_type=UserSanction.SanctionType.WARNING
        ).count()
        temp_bans = UserSanction.objects.filter(
            sanction_type=UserSanction.SanctionType.TEMP_BAN
        ).count()
        perm_bans = UserSanction.objects.filter(
            sanction_type=UserSanction.SanctionType.PERM_BAN
        ).count()

        # 관리 액션 통계
        total_actions = ModerationLog.objects.count()
        recent_actions = ModerationLog.objects.select_related("moderator").order_by(
            "-created_at"
        )[:10]

        data = {
            "total_reports": total_reports,
            "pending_reports": pending_reports,
            "reviewing_reports": reviewing_reports,
            "resolved_reports": resolved_reports,
            "rejected_reports": rejected_reports,
            "total_sanctions": total_sanctions,
            "active_sanctions": active_sanctions,
            "warnings": warnings,
            "temp_bans": temp_bans,
            "perm_bans": perm_bans,
            "total_actions": total_actions,
            "recent_actions": recent_actions,
        }

        serializer = ModerationStatsSerializer(data)
        return Response(serializer.data, status=status.HTTP_200_OK)

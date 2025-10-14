from django.db import models
from django.conf import settings
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType
from django.utils import timezone


class Report(models.Model):
    """신고"""

    class ReportType(models.TextChoices):
        USER = "user", "사용자"
        POST = "post", "게시글"
        COMMENT = "comment", "댓글"
        MESSAGE = "message", "메시지"
        OPEN_CHAT_MESSAGE = "open_chat_message", "오픈 채팅 메시지"

    class ReportReason(models.TextChoices):
        SPAM = "spam", "스팸/광고"
        HARASSMENT = "harassment", "욕설/비방"
        INAPPROPRIATE = "inappropriate", "부적절한 콘텐츠"
        VIOLENCE = "violence", "폭력적 콘텐츠"
        SEXUAL = "sexual", "성적 콘텐츠"
        ILLEGAL = "illegal", "불법 정보"
        FRAUD = "fraud", "사기/사칭"
        OTHER = "other", "기타"

    class Status(models.TextChoices):
        PENDING = "pending", "대기 중"
        REVIEWING = "reviewing", "검토 중"
        RESOLVED = "resolved", "처리 완료"
        REJECTED = "rejected", "반려됨"

    # 신고자
    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="reports_made",
        help_text="신고한 사용자"
    )

    # 신고 대상 (Generic Foreign Key)
    report_type = models.CharField(
        max_length=20,
        choices=ReportType.choices,
        help_text="신고 타입"
    )
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveIntegerField()
    reported_object = GenericForeignKey("content_type", "object_id")

    # 신고 내용
    reason = models.CharField(
        max_length=20,
        choices=ReportReason.choices,
        help_text="신고 사유"
    )
    description = models.TextField(max_length=500, help_text="상세 설명")

    # 처리 상태
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        help_text="처리 상태"
    )

    # 처리 담당자
    reviewer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="reports_reviewed",
        help_text="검토 담당자"
    )

    # 처리 결과
    resolution = models.TextField(
        max_length=500,
        blank=True,
        help_text="처리 결과"
    )
    resolved_at = models.DateTimeField(null=True, blank=True, help_text="처리 완료 시간")

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "신고"
        verbose_name_plural = "신고 목록"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status", "-created_at"]),
            models.Index(fields=["report_type", "-created_at"]),
        ]

    def __str__(self):
        return f"{self.reporter.nickname} reported {self.report_type} ({self.status})"

    def resolve(self, reviewer, resolution):
        """신고 처리"""
        self.status = self.Status.RESOLVED
        self.reviewer = reviewer
        self.resolution = resolution
        self.resolved_at = timezone.now()
        self.save(update_fields=["status", "reviewer", "resolution", "resolved_at", "updated_at"])

    def reject(self, reviewer, resolution):
        """신고 반려"""
        self.status = self.Status.REJECTED
        self.reviewer = reviewer
        self.resolution = resolution
        self.resolved_at = timezone.now()
        self.save(update_fields=["status", "reviewer", "resolution", "resolved_at", "updated_at"])


class UserSanction(models.Model):
    """사용자 제재"""

    class SanctionType(models.TextChoices):
        WARNING = "warning", "경고"
        TEMP_BAN = "temp_ban", "일시 정지"
        PERM_BAN = "perm_ban", "영구 차단"

    # 제재 대상
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="sanctions",
        help_text="제재 대상 사용자"
    )

    # 제재 정보
    sanction_type = models.CharField(
        max_length=20,
        choices=SanctionType.choices,
        help_text="제재 유형"
    )
    reason = models.TextField(max_length=500, help_text="제재 사유")

    # 제재 기간
    start_date = models.DateTimeField(default=timezone.now, help_text="제재 시작 시간")
    end_date = models.DateTimeField(null=True, blank=True, help_text="제재 종료 시간 (영구 차단은 null)")

    # 제재자
    sanctioned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="sanctions_issued",
        help_text="제재를 부여한 관리자"
    )

    # 관련 신고
    related_report = models.ForeignKey(
        Report,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="sanctions",
        help_text="관련 신고"
    )

    # 상태
    is_active = models.BooleanField(default=True, help_text="활성화 여부")

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "사용자 제재"
        verbose_name_plural = "사용자 제재 목록"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "-created_at"]),
            models.Index(fields=["sanction_type", "-created_at"]),
        ]

    def __str__(self):
        return f"{self.user.nickname} - {self.get_sanction_type_display()}"

    def is_expired(self):
        """제재가 만료되었는지 확인"""
        if self.sanction_type == self.SanctionType.PERM_BAN:
            return False
        if self.end_date and timezone.now() > self.end_date:
            return True
        return False

    def deactivate(self):
        """제재 비활성화"""
        self.is_active = False
        self.save(update_fields=["is_active", "updated_at"])


class ModerationLog(models.Model):
    """관리자 액션 로그"""

    class ActionType(models.TextChoices):
        REVIEW_REPORT = "review_report", "신고 검토"
        RESOLVE_REPORT = "resolve_report", "신고 처리"
        REJECT_REPORT = "reject_report", "신고 반려"
        ISSUE_WARNING = "issue_warning", "경고 부여"
        ISSUE_BAN = "issue_ban", "차단 부여"
        REMOVE_BAN = "remove_ban", "차단 해제"
        DELETE_CONTENT = "delete_content", "콘텐츠 삭제"
        RESTORE_CONTENT = "restore_content", "콘텐츠 복구"

    # 관리자
    moderator = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="moderation_logs",
        help_text="관리자"
    )

    # 액션 정보
    action_type = models.CharField(
        max_length=20,
        choices=ActionType.choices,
        help_text="액션 타입"
    )
    description = models.TextField(max_length=500, help_text="액션 설명")

    # 대상 (Generic Foreign Key)
    content_type = models.ForeignKey(
        ContentType,
        on_delete=models.CASCADE,
        null=True,
        blank=True
    )
    object_id = models.PositiveIntegerField(null=True, blank=True)
    target_object = GenericForeignKey("content_type", "object_id")

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "관리 로그"
        verbose_name_plural = "관리 로그 목록"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["moderator", "-created_at"]),
            models.Index(fields=["action_type", "-created_at"]),
        ]

    def __str__(self):
        return f"{self.moderator.nickname} - {self.get_action_type_display()} ({self.created_at})"

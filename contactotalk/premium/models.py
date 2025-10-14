from django.db import models
from django.conf import settings
from django.utils import timezone
from datetime import timedelta


class Subscription(models.Model):
    """구독 플랜"""

    class PlanType(models.TextChoices):
        MONTHLY = "monthly", "월간 구독"
        QUARTERLY = "quarterly", "분기 구독"
        YEARLY = "yearly", "연간 구독"

    name = models.CharField(max_length=100, help_text="구독 플랜 이름")
    plan_type = models.CharField(
        max_length=20,
        choices=PlanType.choices,
        help_text="구독 유형"
    )
    price = models.DecimalField(max_digits=10, decimal_places=2, help_text="가격")
    duration_days = models.IntegerField(help_text="구독 기간 (일)")

    # 프리미엄 혜택
    is_ad_free = models.BooleanField(default=True, help_text="광고 제거")
    unlimited_matches = models.BooleanField(default=True, help_text="무제한 매칭")
    priority_matching = models.BooleanField(default=False, help_text="우선 매칭")
    profile_boost = models.BooleanField(default=False, help_text="프로필 부스트")
    custom_badge = models.BooleanField(default=False, help_text="커스텀 뱃지")

    # 활성화 여부
    is_active = models.BooleanField(default=True, help_text="활성화 여부")

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "구독 플랜"
        verbose_name_plural = "구독 플랜 목록"
        ordering = ["price"]

    def __str__(self):
        return f"{self.name} ({self.get_plan_type_display()}) - {self.price}원"


class UserSubscription(models.Model):
    """사용자 구독"""

    class Status(models.TextChoices):
        ACTIVE = "active", "활성"
        EXPIRED = "expired", "만료"
        CANCELLED = "cancelled", "취소"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="subscriptions",
        help_text="구독 사용자"
    )
    subscription = models.ForeignKey(
        Subscription,
        on_delete=models.PROTECT,
        related_name="user_subscriptions",
        help_text="구독 플랜"
    )

    # 구독 기간
    start_date = models.DateTimeField(default=timezone.now, help_text="시작일")
    end_date = models.DateTimeField(help_text="종료일")

    # 상태
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.ACTIVE,
        help_text="구독 상태"
    )

    # 자동 갱신
    auto_renew = models.BooleanField(default=False, help_text="자동 갱신 여부")

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "사용자 구독"
        verbose_name_plural = "사용자 구독 목록"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "status"]),
            models.Index(fields=["end_date", "status"]),
        ]

    def __str__(self):
        return f"{self.user.nickname} - {self.subscription.name} ({self.status})"

    def is_valid(self):
        """구독이 유효한지 확인"""
        return self.status == self.Status.ACTIVE and timezone.now() < self.end_date

    def is_expired(self):
        """구독이 만료되었는지 확인"""
        return timezone.now() >= self.end_date

    def cancel(self):
        """구독 취소"""
        self.status = self.Status.CANCELLED
        self.auto_renew = False
        self.save(update_fields=["status", "auto_renew", "updated_at"])

    def renew(self):
        """구독 갱신"""
        if self.subscription.is_active:
            self.start_date = timezone.now()
            self.end_date = timezone.now() + timedelta(days=self.subscription.duration_days)
            self.status = self.Status.ACTIVE
            self.save(update_fields=["start_date", "end_date", "status", "updated_at"])
            return True
        return False


class Payment(models.Model):
    """결제 내역"""

    class PaymentMethod(models.TextChoices):
        CARD = "card", "신용/체크카드"
        BANK_TRANSFER = "bank_transfer", "계좌이체"
        MOBILE = "mobile", "휴대폰 결제"
        KAKAOPAY = "kakaopay", "카카오페이"
        TOSS = "toss", "토스"

    class Status(models.TextChoices):
        PENDING = "pending", "대기 중"
        COMPLETED = "completed", "완료"
        FAILED = "failed", "실패"
        REFUNDED = "refunded", "환불"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="payments",
        help_text="결제자"
    )
    user_subscription = models.ForeignKey(
        UserSubscription,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="payments",
        help_text="연관된 구독"
    )

    # 결제 정보
    payment_method = models.CharField(
        max_length=20,
        choices=PaymentMethod.choices,
        help_text="결제 수단"
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2, help_text="결제 금액")
    currency = models.CharField(max_length=3, default="KRW", help_text="통화")

    # 결제 상태
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        help_text="결제 상태"
    )

    # 외부 결제 시스템 정보
    transaction_id = models.CharField(
        max_length=100,
        unique=True,
        help_text="결제 트랜잭션 ID"
    )
    pg_provider = models.CharField(
        max_length=50,
        blank=True,
        help_text="PG사 (예: toss, stripe)"
    )
    receipt_url = models.URLField(blank=True, help_text="영수증 URL")

    # 환불 정보
    refunded_at = models.DateTimeField(null=True, blank=True, help_text="환불 시간")
    refund_reason = models.TextField(max_length=500, blank=True, help_text="환불 사유")

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "결제 내역"
        verbose_name_plural = "결제 내역 목록"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "-created_at"]),
            models.Index(fields=["status", "-created_at"]),
        ]

    def __str__(self):
        return f"{self.user.nickname} - {self.amount}{self.currency} ({self.status})"

    def complete(self):
        """결제 완료 처리"""
        self.status = self.Status.COMPLETED
        self.save(update_fields=["status", "updated_at"])

    def fail(self):
        """결제 실패 처리"""
        self.status = self.Status.FAILED
        self.save(update_fields=["status", "updated_at"])

    def refund(self, reason=""):
        """환불 처리"""
        self.status = self.Status.REFUNDED
        self.refunded_at = timezone.now()
        self.refund_reason = reason
        self.save(update_fields=["status", "refunded_at", "refund_reason", "updated_at"])


class Advertisement(models.Model):
    """광고"""

    class AdType(models.TextChoices):
        BANNER = "banner", "배너 광고"
        VIDEO = "video", "비디오 광고"
        NATIVE = "native", "네이티브 광고"

    class Status(models.TextChoices):
        ACTIVE = "active", "활성"
        PAUSED = "paused", "일시정지"
        ENDED = "ended", "종료"

    # 광고주
    advertiser_name = models.CharField(max_length=100, help_text="광고주 이름")
    advertiser_email = models.EmailField(help_text="광고주 이메일")

    # 광고 정보
    title = models.CharField(max_length=200, help_text="광고 제목")
    description = models.TextField(max_length=500, help_text="광고 설명")
    ad_type = models.CharField(
        max_length=20,
        choices=AdType.choices,
        default=AdType.BANNER,
        help_text="광고 타입"
    )

    # 광고 소재
    image_url = models.URLField(blank=True, help_text="이미지 URL")
    video_url = models.URLField(blank=True, help_text="비디오 URL")
    link_url = models.URLField(help_text="랜딩 페이지 URL")

    # 광고 기간
    start_date = models.DateTimeField(help_text="시작일")
    end_date = models.DateTimeField(help_text="종료일")

    # 타겟팅
    target_countries = models.JSONField(
        default=list,
        help_text="타겟 국가 코드 리스트 (예: ['KOR', 'USA'])"
    )
    target_age_min = models.IntegerField(null=True, blank=True, help_text="최소 연령")
    target_age_max = models.IntegerField(null=True, blank=True, help_text="최대 연령")

    # 광고 예산 및 성과
    budget = models.DecimalField(max_digits=10, decimal_places=2, help_text="예산")
    cost_per_click = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        default=0.10,
        help_text="클릭당 비용 (CPC)"
    )
    total_impressions = models.IntegerField(default=0, help_text="총 노출 수")
    total_clicks = models.IntegerField(default=0, help_text="총 클릭 수")

    # 상태
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.ACTIVE,
        help_text="광고 상태"
    )

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "광고"
        verbose_name_plural = "광고 목록"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status", "-created_at"]),
            models.Index(fields=["start_date", "end_date"]),
        ]

    def __str__(self):
        return f"{self.advertiser_name} - {self.title} ({self.status})"

    def increment_impression(self):
        """노출 수 증가"""
        self.total_impressions += 1
        self.save(update_fields=["total_impressions", "updated_at"])

    def increment_click(self):
        """클릭 수 증가"""
        self.total_clicks += 1
        self.save(update_fields=["total_clicks", "updated_at"])

    def is_active(self):
        """광고가 활성 상태인지 확인"""
        now = timezone.now()
        return (
            self.status == self.Status.ACTIVE
            and self.start_date <= now <= self.end_date
        )

    def get_ctr(self):
        """CTR (Click-Through Rate) 계산"""
        if self.total_impressions == 0:
            return 0.0
        return (self.total_clicks / self.total_impressions) * 100


class AdImpression(models.Model):
    """광고 노출 기록"""

    class ActionType(models.TextChoices):
        IMPRESSION = "impression", "노출"
        CLICK = "click", "클릭"

    advertisement = models.ForeignKey(
        Advertisement,
        on_delete=models.CASCADE,
        related_name="impressions",
        help_text="광고"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="ad_impressions",
        help_text="사용자"
    )

    action_type = models.CharField(
        max_length=20,
        choices=ActionType.choices,
        help_text="액션 타입"
    )

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "광고 노출 기록"
        verbose_name_plural = "광고 노출 기록 목록"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["advertisement", "-created_at"]),
            models.Index(fields=["user", "-created_at"]),
        ]

    def __str__(self):
        return f"{self.user.nickname} - {self.advertisement.title} ({self.action_type})"

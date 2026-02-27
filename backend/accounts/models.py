from django.conf import settings
from django.contrib.auth.models import AbstractUser
from django.db import models


class CustomUser(AbstractUser):
    """
    MarketLens 커스텀 사용자 모델
    - 이메일 기반 로그인
    - 닉네임 표시 (중복 허용)
    - 관심 종목 저장
    - 역할 기반 권한 시스템
    """
    ROLE_CHOICES = [
        ('master', 'Master'),
        ('manager', 'Manager'),
        ('gold', 'Gold'),
        ('regular', 'Regular'),
    ]

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['nickname']

    # 이메일 로그인
    email = models.EmailField(unique=True, db_index=True)

    # username은 Django 호환성 유지용 (자동 생성)
    username = models.CharField(max_length=150, unique=True, blank=True)

    # 닉네임 (화면 표시용, 중복 허용)
    nickname = models.CharField(max_length=50)

    # 역할 (권한 시스템)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='regular')

    # 프로필 정보
    profile_picture = models.ImageField(upload_to='profiles/', blank=True, null=True)
    bio = models.TextField(max_length=200, blank=True)

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # 탈퇴 관련
    deletion_requested_at = models.DateTimeField(null=True, blank=True)
    DELETION_GRACE_DAYS = 7

    # 관심 종목 (JSON 배열)
    watchlist_tickers = models.JSONField(default=list, blank=True)

    class Meta:
        db_table = 'users'
        verbose_name = '사용자'
        verbose_name_plural = '사용자'
        indexes = [
            models.Index(fields=['email']),
            models.Index(fields=['created_at']),
        ]

    def save(self, *args, **kwargs):
        """username을 email에서 자동 생성"""
        if not self.username:
            # 이메일의 @ 앞부분을 username으로 사용
            base_username = self.email.split('@')[0]
            username = base_username

            # 중복 방지: username_1, username_2, ...
            counter = 1
            while CustomUser.objects.filter(username=username).exists():
                username = f"{base_username}_{counter}"
                counter += 1

            self.username = username

        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.nickname} ({self.email})"

    def add_to_watchlist(self, ticker):
        """관심 종목 추가"""
        ticker = ticker.upper()
        if ticker not in self.watchlist_tickers:
            self.watchlist_tickers.append(ticker)
            self.save(update_fields=['watchlist_tickers'])

    def remove_from_watchlist(self, ticker):
        """관심 종목 제거"""
        ticker = ticker.upper()
        if ticker in self.watchlist_tickers:
            self.watchlist_tickers.remove(ticker)
            self.save(update_fields=['watchlist_tickers'])

    def is_watching(self, ticker):
        """관심 종목 포함 여부 확인"""
        return ticker.upper() in self.watchlist_tickers


class DeviceToken(models.Model):
    """FCM 디바이스 토큰"""
    PLATFORM_CHOICES = [('android', 'Android'), ('ios', 'iOS')]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='device_tokens')
    token = models.TextField(unique=True)
    platform = models.CharField(max_length=10, choices=PLATFORM_CHOICES)
    language = models.CharField(max_length=10, default='en')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'accounts_devicetoken'
        indexes = [
            models.Index(fields=['user', 'is_active']),
            models.Index(fields=['token']),
        ]

    def __str__(self):
        return f"{self.user.nickname} ({self.platform})"


class NotificationSubscription(models.Model):
    """종목별 알림 구독 (watchlist 동기화)"""
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notification_subscriptions')
    ticker = models.CharField(max_length=50)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'accounts_notificationsubscription'
        unique_together = ['user', 'ticker']
        indexes = [
            models.Index(fields=['ticker', 'is_active']),
            models.Index(fields=['user', 'is_active']),
        ]

    def __str__(self):
        return f"{self.user.nickname} → {self.ticker}"


class NotificationRateLimit(models.Model):
    """1시간 1알림 제한 (일반 알림용)"""
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, primary_key=True)
    last_general_notified_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'accounts_notificationratelimit'


class NotificationHistory(models.Model):
    """사용자별 알림 히스토리 (rate limit 무관하게 모든 대상자 기록)"""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='notification_history',
    )
    title = models.CharField(max_length=200)
    body = models.TextField()
    notification_type = models.CharField(max_length=30)
    ticker = models.CharField(max_length=50, blank=True, default='')
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'accounts_notification_history'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['user', 'is_read']),
        ]

    def __str__(self):
        return f"{self.user_id} [{self.notification_type}] {self.title}"

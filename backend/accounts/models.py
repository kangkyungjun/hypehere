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

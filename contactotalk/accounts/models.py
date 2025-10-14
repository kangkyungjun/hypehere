from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone


class User(AbstractUser):
    """커스텀 사용자 모델 - 6단계 권한 시스템"""

    class Role(models.TextChoices):
        VISITOR = "visitor", "Visitor"
        USER = "user", "User"
        PREMIUM_USER = "premiumuser", "Premium User"
        MANAGER = "manager", "Manager"
        PRIME = "prime", "Prime Admin"
        OWNER = "owner", "Owner"

    class Gender(models.TextChoices):
        MALE = "male", "남성"
        FEMALE = "female", "여성"
        UNDISCLOSED = "undisclosed", "선택 안함"

    # username은 중복 가능하도록 오버라이드
    username = models.CharField(
        max_length=150,
        unique=False,  # 중복 가능
        help_text="사용자명 (중복 가능)"
    )

    # email은 unique로 변경 (로그인 식별자로 사용)
    email = models.EmailField(
        unique=True,  # 중복 불가
        help_text="이메일 (로그인 ID)"
    )

    role = models.CharField(
        max_length=20,
        choices=Role.choices,
        default=Role.VISITOR,  # 가입 전 기본값
        help_text="사용자 권한 레벨"
    )

    # 로그인 시 email 사용
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']  # createsuperuser 시 요구되는 필드

    # 프로필 정보
    nickname = models.CharField(
        max_length=20,
        unique=True,
        null=True,
        blank=True,
        help_text="사용자 닉네임 (최대 20자)"
    )
    country_code = models.CharField(
        max_length=3,
        help_text="ISO 3166-1 alpha-3 국가 코드"
    )
    bio = models.TextField(
        max_length=500,
        blank=True,
        help_text="자기소개"
    )
    gender = models.CharField(
        max_length=20,
        choices=Gender.choices,
        null=True,
        blank=True,
        help_text="성별 (남성/여성/선택 안함)"
    )

    # 프리미엄 관련
    premium_until = models.DateTimeField(
        null=True,
        blank=True,
        help_text="프리미엄 만료 일시"
    )

    # 매칭 제한
    daily_match_count = models.IntegerField(
        default=0,
        help_text="2시간 내 매칭 횟수"
    )
    last_match_reset = models.DateTimeField(
        auto_now_add=True,
        help_text="마지막 매칭 카운트 리셋 시각"
    )

    # 계정 상태
    is_banned = models.BooleanField(
        default=False,
        help_text="계정 정지 여부"
    )
    banned_until = models.DateTimeField(
        null=True,
        blank=True,
        help_text="정지 해제 일시 (None이면 영구)"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "사용자"
        verbose_name_plural = "사용자 목록"

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"

    def is_premium_active(self):
        """프리미엄 활성 상태 확인"""
        if self.role == self.Role.PREMIUM_USER and self.premium_until:
            return timezone.now() < self.premium_until
        return False

    def can_match_today(self):
        """매칭 가능 여부 (2시간당 10회 제한)"""
        # 프리미엄 이상 권한은 무제한
        if self.role in [
            self.Role.PREMIUM_USER,
            self.Role.MANAGER,
            self.Role.PRIME,
            self.Role.OWNER,
        ]:
            return True

        # 2시간이 지났으면 카운트 리셋
        now = timezone.now()
        if self.last_match_reset:
            time_diff = (now - self.last_match_reset).total_seconds()
            if time_diff >= 7200:  # 2시간 = 7200초
                self.daily_match_count = 0
                self.last_match_reset = now
                self.save(update_fields=["daily_match_count", "last_match_reset"])

        # 일반 사용자는 2시간당 10회 제한
        return self.daily_match_count < 10

    def increment_match_count(self):
        """매칭 카운트 증가"""
        if self.role == self.Role.USER:
            self.daily_match_count += 1
            self.save(update_fields=["daily_match_count"])

    def is_banned_now(self):
        """현재 정지 상태인지 확인"""
        if not self.is_banned:
            return False

        # 영구 정지
        if self.banned_until is None:
            return True

        # 정지 기간 확인
        if timezone.now() < self.banned_until:
            return True

        # 정지 기간 만료
        self.is_banned = False
        self.banned_until = None
        self.save(update_fields=["is_banned", "banned_until"])
        return False

    def has_admin_access(self):
        """관리자 권한 여부"""
        return self.role in [
            self.Role.MANAGER,
            self.Role.PRIME,
            self.Role.OWNER,
        ]

    def has_full_access(self):
        """최고 관리자 권한 여부"""
        return self.role in [self.Role.PRIME, self.Role.OWNER]


class Interest(models.Model):
    """관심사 카테고리"""

    class Category(models.TextChoices):
        MUSIC = "music", "음악"
        ENTERTAINMENT = "entertainment", "엔터테인먼트"
        TRAVEL = "travel", "여행"
        TECH = "tech", "기술"
        LANGUAGE = "language", "언어"
        RELATIONSHIP = "relationship", "관계"
        SPORTS = "sports", "스포츠"
        FOOD = "food", "음식"
        ART = "art", "예술"
        GAME = "game", "게임"
        FITNESS = "fitness", "운동/피트니스"
        BOOK = "book", "독서"
        MOVIE = "movie", "영화"
        FASHION = "fashion", "패션"
        PHOTOGRAPHY = "photography", "사진"
        OTHER = "other", "기타"

    category = models.CharField(
        max_length=20,
        choices=Category.choices,
        help_text="관심사 대분류"
    )
    name = models.CharField(
        max_length=50,
        unique=True,
        help_text="관심사 이름 (기본)"
    )
    name_ko = models.CharField(
        max_length=50,
        help_text="한국어 이름"
    )
    name_en = models.CharField(
        max_length=50,
        help_text="영어 이름"
    )
    icon = models.CharField(
        max_length=10,
        blank=True,
        help_text="아이콘 이모지"
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "관심사"
        verbose_name_plural = "관심사 목록"
        ordering = ["category", "name"]

    def __str__(self):
        return f"{self.get_category_display()}: {self.name_ko}"


class UserInterest(models.Model):
    """사용자-관심사 중간 테이블"""

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="user_interests"
    )
    interest = models.ForeignKey(
        Interest,
        on_delete=models.CASCADE,
        related_name="user_interests"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "interest")
        verbose_name = "사용자 관심사"
        verbose_name_plural = "사용자 관심사 목록"

    def __str__(self):
        return f"{self.user.username} - {self.interest.name_ko}"

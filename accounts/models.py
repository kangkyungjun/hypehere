from django.db import models
from django.contrib.auth.models import AbstractUser, UserManager as BaseUserManager
from django.core.validators import MinLengthValidator
from django.conf import settings
from django.utils.translation import gettext_lazy as _
import uuid


def profile_picture_upload_path(instance, filename):
    """
    Generate upload path for profile pictures with UUID-based filename.

    This function:
    - Creates unique filenames to prevent conflicts
    - Always saves as .jpg (JPEG format)
    - Organizes files in profile_pictures/ directory

    Args:
        instance: User model instance
        filename: Original uploaded filename (ignored for security)

    Returns:
        str: Upload path like 'profile_pictures/550e8400-e29b-41d4-a716-446655440000.jpg'
    """
    # Generate UUID for filename (security best practice)
    new_filename = f"{uuid.uuid4()}.jpg"
    return f"profile_pictures/{new_filename}"


class UserManager(BaseUserManager):
    """Custom user manager that uses email as the unique identifier"""

    def create_user(self, email, nickname, password=None, **extra_fields):
        """Create and save a regular user with the given email, nickname, and password"""
        if not email:
            raise ValueError('The Email field must be set')
        if not nickname:
            raise ValueError('The Nickname field must be set')

        email = self.normalize_email(email)

        # Auto-generate username from email
        base_username = email.split('@')[0]
        username = base_username
        counter = 1
        while self.model.objects.filter(username=username).exists():
            username = f"{base_username}{counter}"
            counter += 1

        user = self.model(email=email, username=username, nickname=nickname, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, nickname, password=None, **extra_fields):
        """Create and save a superuser with the given email, nickname, and password"""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, nickname, password, **extra_fields)


class User(AbstractUser):
    """Custom User model with extended fields for account management

    Authentication:
        - Uses email as USERNAME_FIELD (login ID)
        - username is auto-generated from email and kept for Django compatibility
        - nickname is the display name (duplicates allowed)
    """

    # Custom manager
    objects = UserManager()

    # Authentication fields
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['nickname']  # Only required for createsuperuser

    # Override default fields
    email = models.EmailField(unique=True, blank=False)
    username = models.CharField(max_length=150, unique=True, blank=True)  # Auto-generated

    # New display name field
    nickname = models.CharField(max_length=50, blank=False, default='user', verbose_name='닉네임')

    # Removed fields (keep as blank for migration safety)
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=150, blank=True)

    # Profile information
    date_of_birth = models.DateField(blank=True, null=True)
    bio = models.TextField(max_length=200, blank=True)
    profile_picture = models.ImageField(
        upload_to=profile_picture_upload_path,
        blank=True,
        null=True,
        verbose_name='프로필 사진',
        help_text='프로필 사진 (자동으로 1024x1024, 85% 품질로 최적화됩니다)'
    )

    # Address information
    address = models.CharField(max_length=255, blank=True)
    city = models.CharField(max_length=100, blank=True)
    country = models.CharField(max_length=100, blank=True)
    postal_code = models.CharField(max_length=20, blank=True)

    # Personal information
    gender = models.CharField(
        max_length=20,
        choices=[
            ('male', '남성'),
            ('female', '여성'),
            ('other', '기타'),
            ('prefer_not_to_say', '밝히지 않음')
        ],
        blank=True,
        null=True,
        verbose_name='성별'
    )

    # Language learning preferences
    native_language = models.CharField(
        max_length=2,
        choices=[
            ('ko', '한국어'),
            ('en', 'English'),
            ('ja', '日本語'),
            ('zh', '中文'),
            ('es', 'Español'),
            ('fr', 'Français'),
            ('de', 'Deutsch')
        ],
        blank=True,
        default='',
        verbose_name='모국어'
    )
    target_language = models.CharField(
        max_length=2,
        choices=[
            ('ko', '한국어'),
            ('en', 'English'),
            ('ja', '日本語'),
            ('zh', '中文'),
            ('es', 'Español'),
            ('fr', 'Français'),
            ('de', 'Deutsch')
        ],
        blank=True,
        default='',
        verbose_name='학습 언어'
    )

    # Account status
    is_verified = models.BooleanField(default=False)
    is_premium = models.BooleanField(default=False)
    is_private = models.BooleanField(default=False, verbose_name='Private Profile')

    # Permission levels
    is_prime = models.BooleanField(default=False, verbose_name='프리미엄 관리자')
    is_gold = models.BooleanField(default=False, verbose_name='골드 사용자')

    # Moderation tracking
    report_count = models.IntegerField(
        default=0,
        verbose_name='누적 신고 횟수',
        help_text='resolved/reviewing 상태 신고만 카운트'
    )

    # Privacy settings
    show_followers_list = models.CharField(
        max_length=20,
        choices=[
            ('everyone', 'Everyone'),
            ('followers', 'Followers Only'),
            ('nobody', 'Nobody')
        ],
        default='everyone',
        verbose_name='Followers List Visibility'
    )
    show_following_list = models.CharField(
        max_length=20,
        choices=[
            ('everyone', 'Everyone'),
            ('followers', 'Followers Only'),
            ('nobody', 'Nobody')
        ],
        default='everyone',
        verbose_name='Following List Visibility'
    )

    # Account management
    is_deactivated = models.BooleanField(default=False, verbose_name='Account Deactivated')
    deactivated_at = models.DateTimeField(null=True, blank=True, verbose_name='Deactivation Date')
    deletion_requested_at = models.DateTimeField(null=True, blank=True, verbose_name='Deletion Request Date')

    # Account suspension (temporary ban by admin)
    is_suspended = models.BooleanField(default=False, verbose_name='Account Suspended')
    suspended_until = models.DateTimeField(null=True, blank=True, verbose_name='Suspension End Date')
    suspension_reason = models.TextField(blank=True, verbose_name='Suspension Reason')
    suspended_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='suspended_users',
        verbose_name='Suspended By Admin'
    )
    suspended_at = models.DateTimeField(null=True, blank=True, verbose_name='Suspension Start Date')

    # Permanent ban by admin
    is_banned = models.BooleanField(default=False, verbose_name='Account Banned')
    banned_at = models.DateTimeField(null=True, blank=True, verbose_name='Ban Date')
    ban_reason = models.TextField(blank=True, verbose_name='Ban Reason')
    banned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='banned_users',
        verbose_name='Banned By Admin'
    )

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_login_ip = models.GenericIPAddressField(blank=True, null=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'User'
        verbose_name_plural = 'Users'

    def save(self, *args, **kwargs):
        """Override save to auto-generate username from email"""
        if not self.username:
            # Generate username from email
            base_username = self.email.split('@')[0]
            username = base_username

            # Ensure uniqueness
            counter = 1
            while User.objects.filter(username=username).exclude(pk=self.pk).exists():
                username = f"{base_username}{counter}"
                counter += 1

            self.username = username

        super().save(*args, **kwargs)

    def __str__(self):
        return self.email

    @property
    def display_name(self):
        """Return user's display name (nickname or email)"""
        return self.nickname or self.email.split('@')[0]

    def increment_report_count(self):
        """신고 카운트 증가 (resolved/reviewing로 변경 시)"""
        self.report_count = models.F('report_count') + 1
        self.save(update_fields=['report_count'])
        self.refresh_from_db()

    def decrement_report_count(self):
        """신고 카운트 감소 (dismissed로 변경 시)"""
        if self.report_count > 0:
            self.report_count = models.F('report_count') - 1
            self.save(update_fields=['report_count'])
            self.refresh_from_db()

    def get_report_count(self):
        """현재 신고 카운트 조회"""
        return self.report_count

    def get_follower_count(self):
        """Return number of followers"""
        return self.followers.count()

    def get_following_count(self):
        """Return number of users this user follows"""
        return self.following.count()

    def is_following(self, user):
        """Check if this user follows another user"""
        return self.following.filter(following=user).exists()

    def is_follower(self, user):
        """Check if another user follows this user"""
        return self.followers.filter(follower=user).exists()

    def is_blocking(self, user):
        """Check if this user is actively blocking another user"""
        return self.blocking.filter(blocked=user, is_active=True).exists()

    def is_blocked_by(self, user):
        """Check if this user is actively blocked by another user"""
        return self.blocked_by.filter(blocker=user, is_active=True).exists()

    def get_blocked_users_count(self):
        """Return number of users this user has blocked"""
        return self.blocking.count()

    def can_cancel_deletion(self):
        """Check if deletion can be cancelled (within 30 days)"""
        if not self.deletion_requested_at:
            return False
        from django.utils import timezone
        from datetime import timedelta
        grace_period = timezone.now() - self.deletion_requested_at
        return grace_period < timedelta(days=30)

    def days_until_deletion(self):
        """Return number of days until account deletion"""
        if not self.deletion_requested_at:
            return None
        from django.utils import timezone
        grace_period = timezone.now() - self.deletion_requested_at
        return max(0, 30 - grace_period.days)

    # Suspension/Ban management methods
    def suspend_account(self, duration_days, reason, admin_user):
        """Suspend account for specified number of days"""
        from django.utils import timezone
        from datetime import timedelta

        self.is_suspended = True
        self.suspended_at = timezone.now()
        self.suspended_until = timezone.now() + timedelta(days=duration_days)
        self.suspension_reason = reason
        self.suspended_by = admin_user
        self.save(update_fields=['is_suspended', 'suspended_at', 'suspended_until', 'suspension_reason', 'suspended_by'])

    def lift_suspension(self):
        """Remove suspension from account"""
        self.is_suspended = False
        self.suspended_until = None
        self.save(update_fields=['is_suspended', 'suspended_until'])

    def ban_account(self, reason, admin_user):
        """Permanently ban account"""
        from django.utils import timezone

        self.is_banned = True
        self.banned_at = timezone.now()
        self.ban_reason = reason
        self.banned_by = admin_user
        self.save(update_fields=['is_banned', 'banned_at', 'ban_reason', 'banned_by'])

    def unban_account(self):
        """Remove permanent ban from account"""
        self.is_banned = False
        self.save(update_fields=['is_banned'])

    def is_currently_suspended(self):
        """Check if account is currently suspended (within suspension period)"""
        if not self.is_suspended or not self.suspended_until:
            return False
        from django.utils import timezone
        return timezone.now() < self.suspended_until

    def get_suspension_time_remaining(self):
        """Return timedelta of remaining suspension time, or None if not suspended"""
        if not self.is_currently_suspended():
            return None
        from django.utils import timezone
        return self.suspended_until - timezone.now()

    def get_active_report_count(self):
        """Get count of active reports (within 1 month)"""
        from django.utils import timezone
        from datetime import timedelta
        from posts.models import PostReport, CommentReport
        from chat.models import Report

        cutoff = timezone.now() - timedelta(days=30)

        post_reports = PostReport.objects.filter(
            reported_user=self,
            status='resolved',
            reviewed_at__gte=cutoff
        ).count()

        comment_reports = CommentReport.objects.filter(
            reported_user=self,
            status='resolved',
            reviewed_at__gte=cutoff
        ).count()

        chat_reports = Report.objects.filter(
            reported_user=self,
            status='resolved',
            reviewed_at__gte=cutoff
        ).count()

        return post_reports + comment_reports + chat_reports

    # Permission management methods
    @property
    def has_gold_features(self):
        """유료 기능 접근 권한 (GoldUser, Staff, Prime, Superuser 모두 포함)"""
        return self.is_gold or self.is_staff or self.is_superuser

    def can_assign_role(self, target_role):
        """현재 사용자가 target_role을 부여할 수 있는지 검증

        Args:
            target_role (str): 부여하려는 역할 ('user', 'gold', 'staff', 'prime', 'superuser')

        Returns:
            bool: 권한 부여 가능 여부

        Permission Hierarchy:
            - User/GoldUser: 권한 부여 불가
            - Staff: user, gold, staff까지만 부여 가능
            - Prime: user, gold, staff까지만 부여 가능 (Prime은 Superuser만 부여 가능)
            - Superuser: 모든 권한 부여 가능
        """
        if self.is_superuser:
            # Superuser는 모든 권한 부여 가능
            return True

        if self.is_prime or self.is_staff:
            # Prime과 Staff는 user, gold, staff까지만 부여 가능
            return target_role in ['user', 'gold', 'staff']

        # User, GoldUser는 권한 부여 불가
        return False


class Follow(models.Model):
    """Follow relationship between users"""
    follower = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='following'  # follower.following.all() = users they follow
    )
    following = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='followers'  # following.followers.all() = users who follow them
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ['-created_at']
        unique_together = ['follower', 'following']  # Prevent duplicate follows
        verbose_name = 'Follow'
        verbose_name_plural = 'Follows'
        indexes = [
            models.Index(fields=['follower', '-created_at']),
            models.Index(fields=['following', '-created_at']),
        ]

    def __str__(self):
        return f"{self.follower.nickname} follows {self.following.nickname}"


class Block(models.Model):
    """Block relationship between users"""
    blocker = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='blocking',  # blocker.blocking.all() = users they blocked
        verbose_name='Blocker'
    )
    blocked = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='blocked_by',  # blocked.blocked_by.all() = users who blocked them
        verbose_name='Blocked User'
    )
    is_active = models.BooleanField(default=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    unblocked_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']
        unique_together = ['blocker', 'blocked']  # Prevent duplicate blocks
        verbose_name = 'Block'
        verbose_name_plural = 'Blocks'
        indexes = [
            models.Index(fields=['blocker', 'is_active', '-created_at']),
            models.Index(fields=['blocked', 'is_active', '-created_at']),
        ]

    def __str__(self):
        return f"{self.blocker.nickname} blocks {self.blocked.nickname}"


class SupportTicket(models.Model):
    """Customer support ticket model for user inquiries"""

    CATEGORY_CHOICES = [
        ('account', _('계정 관련')),
        ('payment', _('결제 문의')),
        ('technical', _('기술 지원')),
        ('feature', _('기능 제안')),
        ('other', _('기타')),
    ]

    STATUS_CHOICES = [
        ('pending', _('대기 중')),
        ('answered', _('답변 완료')),
    ]

    # Ticket information
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='support_tickets',
        verbose_name=_('작성자')
    )
    category = models.CharField(
        max_length=20,
        choices=CATEGORY_CHOICES,
        verbose_name=_('카테고리')
    )
    title = models.CharField(max_length=200, verbose_name=_('제목'))
    content = models.TextField(verbose_name=_('내용'))
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending',
        verbose_name=_('상태')
    )

    # Admin response
    admin_response = models.TextField(blank=True, verbose_name=_('관리자 답변'))
    responded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='support_responses',
        verbose_name=_('답변 관리자')
    )
    responded_at = models.DateTimeField(null=True, blank=True, verbose_name='답변 시간')

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='작성 시간')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='수정 시간')

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Support Ticket'
        verbose_name_plural = 'Support Tickets'
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['status', '-created_at']),
        ]

    def __str__(self):
        return f"[{self.get_category_display()}] {self.title}"

    def has_response(self):
        """Check if admin has responded"""
        return bool(self.admin_response)


class PasswordResetAttempt(models.Model):
    """
    Track password reset attempts for rate limiting.

    This model records each password reset request to prevent abuse.
    Rate limiting: Maximum 3 attempts per email per hour.
    """
    email = models.EmailField(verbose_name='이메일')
    attempted_at = models.DateTimeField(auto_now_add=True, verbose_name='시도 시간')
    ip_address = models.GenericIPAddressField(null=True, blank=True, verbose_name='IP 주소')

    class Meta:
        ordering = ['-attempted_at']
        verbose_name = 'Password Reset Attempt'
        verbose_name_plural = 'Password Reset Attempts'
        indexes = [
            models.Index(fields=['email', '-attempted_at']),
        ]

    def __str__(self):
        return f"{self.email} - {self.attempted_at.strftime('%Y-%m-%d %H:%M:%S')}"


class UserReport(models.Model):
    """
    User reports for moderation.

    Users can report other users for violations of community guidelines.
    Similar structure to PostReport and CommentReport for consistency.
    """
    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='user_reports_made',
        verbose_name=_('신고자')
    )
    reported_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='user_reports_received',
        verbose_name=_('신고된 사용자')
    )

    REPORT_TYPES = [
        ('abuse', _('욕설/비방')),
        ('spam', _('스팸/광고')),
        ('inappropriate', _('부적절한 내용')),
        ('harassment', _('성희롱')),
        ('other', _('기타'))
    ]
    report_type = models.CharField(
        max_length=20,
        choices=REPORT_TYPES,
        verbose_name=_('신고 유형')
    )
    description = models.TextField(
        blank=True,
        verbose_name=_('상세 설명')
    )

    STATUS_CHOICES = [
        ('pending', _('대기 중')),
        ('reviewing', _('검토 중')),
        ('resolved', _('처리 완료')),
        ('dismissed', _('기각'))
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending',
        verbose_name=_('상태')
    )

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_('신고 시간'))
    reviewed_at = models.DateTimeField(null=True, blank=True, verbose_name=_('검토 시간'))
    admin_note = models.TextField(blank=True, verbose_name=_('관리자 메모'))

    # Admin tracking
    resolved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='user_reports_resolved',
        verbose_name=_('처리 관리자')
    )

    class Meta:
        ordering = ['-created_at']
        verbose_name = _('사용자 신고')
        verbose_name_plural = _('사용자 신고')
        indexes = [
            models.Index(fields=['reporter', '-created_at']),
            models.Index(fields=['reported_user', '-created_at']),
            models.Index(fields=['status', '-created_at']),
        ]
        # Prevent duplicate reports
        constraints = [
            models.UniqueConstraint(
                fields=['reporter', 'reported_user', 'report_type'],
                condition=models.Q(status='pending'),
                name='unique_pending_user_report'
            )
        ]

    def __str__(self):
        return f"{self.reporter.nickname} reported {self.reported_user.nickname} - {self.get_report_type_display()}"

    def resolve(self, admin_user, note=''):
        """Mark report as resolved and increment reported user's report count"""
        self.status = 'resolved'
        self.reviewed_at = models.timezone.now()
        self.resolved_by = admin_user
        self.admin_note = note
        self.save()

        # Increment reported user's report count
        self.reported_user.increment_report_count()

    def dismiss(self, admin_user, note=''):
        """Mark report as dismissed"""
        self.status = 'dismissed'
        self.reviewed_at = models.timezone.now()
        self.resolved_by = admin_user
        self.admin_note = note
        self.save()


class LegalDocument(models.Model):
    """
    Editable legal documents for Terms, Privacy Policy, Cookie Policy, and Community Guidelines.

    Supports multi-language content with version control.
    Editable by Prime users (is_prime=True) and Superusers.
    """
    DOCUMENT_TYPES = [
        ('terms', _('이용약관')),
        ('privacy', _('개인정보처리방침')),
        ('cookies', _('쿠키 정책')),
        ('community', _('커뮤니티 가이드라인')),
    ]

    LANGUAGE_CHOICES = [
        ('ko', '한국어'),
        ('en', 'English'),
        ('ja', '日本語'),
        ('es', 'Español'),
    ]

    document_type = models.CharField(
        max_length=20,
        choices=DOCUMENT_TYPES,
        verbose_name=_('문서 유형')
    )
    language = models.CharField(
        max_length=2,
        choices=LANGUAGE_CHOICES,
        verbose_name=_('언어')
    )
    title = models.CharField(
        max_length=200,
        verbose_name=_('제목')
    )
    content = models.TextField(
        verbose_name=_('내용'),
        help_text='HTML 형식으로 작성'
    )
    version = models.CharField(
        max_length=20,
        verbose_name=_('버전'),
        help_text='예: 1.0, 1.1, 2.0'
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name=_('활성 상태'),
        help_text='언어별로 하나의 문서만 활성화 가능'
    )
    effective_date = models.DateField(
        verbose_name=_('시행일'),
        help_text='이 버전이 유효하게 되는 날짜'
    )

    # Tracking fields
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='legal_docs_created',
        verbose_name=_('작성자')
    )
    modified_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='legal_docs_modified',
        verbose_name=_('수정자')
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('생성 시간')
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_('수정 시간')
    )

    class Meta:
        ordering = ['-effective_date', '-created_at']
        verbose_name = _('법적 문서')
        verbose_name_plural = _('법적 문서')
        indexes = [
            models.Index(fields=['document_type', 'language', 'is_active']),
            models.Index(fields=['document_type', '-effective_date']),
        ]
        # Ensure only one active document per type and language
        constraints = [
            models.UniqueConstraint(
                fields=['document_type', 'language'],
                condition=models.Q(is_active=True),
                name='unique_active_legal_document'
            )
        ]

    def __str__(self):
        return f"{self.get_document_type_display()} ({self.get_language_display()}) v{self.version}"

    def save(self, *args, **kwargs):
        """Override save to create version history"""
        # If this is an update to an existing document, create version history
        if self.pk:
            try:
                old_version = LegalDocument.objects.get(pk=self.pk)
                # Only create history if content changed
                if old_version.content != self.content:
                    LegalDocumentVersion.objects.create(
                        document=self,
                        content=old_version.content,
                        version=old_version.version,
                        created_by=old_version.modified_by or old_version.created_by
                    )
            except LegalDocument.DoesNotExist:
                pass

        super().save(*args, **kwargs)

    def get_version_history(self):
        """Get all versions of this document"""
        return self.versions.all().order_by('-created_at')


class LegalDocumentVersion(models.Model):
    """
    Version history for legal documents.

    Stores previous versions when documents are updated.
    Allows rollback to previous versions.
    """
    document = models.ForeignKey(
        LegalDocument,
        on_delete=models.CASCADE,
        related_name='versions',
        verbose_name=_('문서')
    )
    content = models.TextField(
        verbose_name=_('내용')
    )
    version = models.CharField(
        max_length=20,
        verbose_name=_('버전')
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        verbose_name=_('작성자')
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('생성 시간')
    )

    class Meta:
        ordering = ['-created_at']
        verbose_name = _('법적 문서 버전')
        verbose_name_plural = _('법적 문서 버전')
        indexes = [
            models.Index(fields=['document', '-created_at']),
        ]

    def __str__(self):
        return f"{self.document.get_document_type_display()} v{self.version} ({self.created_at.strftime('%Y-%m-%d')})"

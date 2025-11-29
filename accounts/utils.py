"""
Utility functions for accounts app
"""


def format_timedelta(td):
    """
    Format timedelta to Korean-friendly string format

    Args:
        td: timedelta object

    Returns:
        str: Formatted string like "2일 5시간 30분" or "1분 미만"
    """
    if not td:
        return ""

    total_seconds = int(td.total_seconds())

    # If negative or zero, return "만료됨"
    if total_seconds <= 0:
        return "만료됨"

    days = td.days
    hours = (total_seconds % 86400) // 3600
    minutes = (total_seconds % 3600) // 60

    parts = []
    if days > 0:
        parts.append(f"{days}일")
    if hours > 0:
        parts.append(f"{hours}시간")
    if minutes > 0:
        parts.append(f"{minutes}분")

    return " ".join(parts) if parts else "1분 미만"


# Password Reset Utilities

import secrets
import string
from datetime import timedelta
from django.utils import timezone
from django.core.mail import send_mail
from django.conf import settings
from django.template.loader import render_to_string
from django.utils.translation import gettext as _


def generate_temporary_password(length=12):
    """
    Generate a secure random temporary password.

    Args:
        length (int): Length of the password (default: 12)

    Returns:
        str: A random password containing uppercase, lowercase, digits, and symbols

    Example:
        >>> password = generate_temporary_password()
        >>> len(password)
        12
    """
    # Define character sets
    uppercase = string.ascii_uppercase
    lowercase = string.ascii_lowercase
    digits = string.digits
    symbols = '!@#$%^&*'

    # Ensure at least one character from each set
    password = [
        secrets.choice(uppercase),
        secrets.choice(lowercase),
        secrets.choice(digits),
        secrets.choice(symbols),
    ]

    # Fill the rest with random characters from all sets
    all_characters = uppercase + lowercase + digits + symbols
    password += [secrets.choice(all_characters) for _ in range(length - 4)]

    # Shuffle the password to avoid predictable patterns
    secrets.SystemRandom().shuffle(password)

    return ''.join(password)


def send_password_reset_email(user, temporary_password):
    """
    Send password reset email with temporary password.

    Args:
        user: User model instance
        temporary_password (str): The temporary password to send

    Returns:
        bool: True if email was sent successfully, False otherwise
    """
    subject = _('[HypeHere] 임시 비밀번호 발급')

    # Prepare email context
    context = {
        'user': user,
        'temporary_password': temporary_password,
        'login_url': f"{settings.SITE_URL}/accounts/login/" if hasattr(settings, 'SITE_URL') else 'http://127.0.0.1:8000/accounts/login/',
    }

    # Render email template
    try:
        html_message = render_to_string('accounts/password_reset/email.html', context)
        plain_message = f"""
안녕하세요,

비밀번호 재설정을 요청하셨습니다.
아래 임시 비밀번호로 로그인하신 후, 반드시 새 비밀번호로 변경해주세요.

임시 비밀번호: {temporary_password}

로그인: {context['login_url']}

보안을 위해 로그인 후 즉시 비밀번호를 변경하시기 바랍니다.

감사합니다.
HypeHere 팀
        """

        # Send email
        send_mail(
            subject=subject,
            message=plain_message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            html_message=html_message,
            fail_silently=False,
        )
        return True
    except Exception as e:
        print(f"Error sending password reset email: {e}")
        return False


def check_rate_limit(email, max_attempts=3, time_window_hours=1):
    """
    Check if the email has exceeded the rate limit for password reset requests.

    Args:
        email (str): The email address to check
        max_attempts (int): Maximum number of attempts allowed (default: 3)
        time_window_hours (int): Time window in hours (default: 1)

    Returns:
        tuple: (allowed: bool, attempts_count: int, time_remaining: str or None)

    Example:
        >>> allowed, count, time_remaining = check_rate_limit('user@example.com')
        >>> if not allowed:
        ...     print(f"Too many attempts. Try again in {time_remaining}")
    """
    from accounts.models import PasswordResetAttempt

    # Calculate time threshold
    time_threshold = timezone.now() - timedelta(hours=time_window_hours)

    # Count recent attempts
    recent_attempts = PasswordResetAttempt.objects.filter(
        email=email,
        attempted_at__gte=time_threshold
    ).order_by('-attempted_at')

    attempts_count = recent_attempts.count()

    if attempts_count >= max_attempts:
        # Calculate time remaining until oldest attempt expires
        oldest_attempt = recent_attempts.last()
        if oldest_attempt:
            time_until_reset = oldest_attempt.attempted_at + timedelta(hours=time_window_hours) - timezone.now()
            minutes_remaining = int(time_until_reset.total_seconds() / 60)

            if minutes_remaining > 60:
                time_remaining = f"{minutes_remaining // 60}시간 {minutes_remaining % 60}분"
            else:
                time_remaining = f"{minutes_remaining}분"

            return False, attempts_count, time_remaining

    return True, attempts_count, None


def record_password_reset_attempt(email, ip_address=None):
    """
    Record a password reset attempt for rate limiting.

    Args:
        email (str): The email address
        ip_address (str, optional): The IP address of the requester

    Returns:
        PasswordResetAttempt: The created attempt record
    """
    from accounts.models import PasswordResetAttempt

    return PasswordResetAttempt.objects.create(
        email=email,
        ip_address=ip_address
    )


def cleanup_old_password_reset_attempts(days=7):
    """
    Clean up password reset attempts older than specified days.
    This should be run periodically (e.g., via cron job or Celery task).

    Args:
        days (int): Delete attempts older than this many days (default: 7)

    Returns:
        int: Number of records deleted
    """
    from accounts.models import PasswordResetAttempt

    threshold = timezone.now() - timedelta(days=days)
    deleted_count, _ = PasswordResetAttempt.objects.filter(
        attempted_at__lt=threshold
    ).delete()

    return deleted_count

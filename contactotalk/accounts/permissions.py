from rest_framework import permissions
from .models import User


class IsVisitor(permissions.BasePermission):
    """Visitor 권한 (읽기 전용)"""

    def has_permission(self, request, view):
        # Visitor는 GET 요청만 가능
        if request.method in permissions.SAFE_METHODS:
            return True
        return False


class IsUser(permissions.BasePermission):
    """일반 사용자 권한"""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        # visitor는 접근 불가
        return request.user.role != User.Role.VISITOR


class IsPremiumUser(permissions.BasePermission):
    """프리미엄 사용자 권한"""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        return request.user.role in [
            User.Role.PREMIUM_USER,
            User.Role.MANAGER,
            User.Role.PRIME,
            User.Role.OWNER,
        ]


class IsManager(permissions.BasePermission):
    """운영자 권한"""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        return request.user.has_admin_access()


class IsPrime(permissions.BasePermission):
    """준 최고 관리자 권한"""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        return request.user.has_full_access()


class IsOwner(permissions.BasePermission):
    """최고 관리자 권한"""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        return request.user.role == User.Role.OWNER


class IsNotBanned(permissions.BasePermission):
    """계정 정지되지 않은 사용자"""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return True  # 비로그인 사용자는 통과

        # 계정 정지 확인
        return not request.user.is_banned_now()

    message = "귀하의 계정은 정지되었습니다. 관리자에게 문의하세요."


class IsOwnerOrReadOnly(permissions.BasePermission):
    """객체의 소유자이거나 읽기 전용"""

    def has_object_permission(self, request, view, obj):
        # 읽기 권한은 모든 요청에 허용
        if request.method in permissions.SAFE_METHODS:
            return True

        # 쓰기 권한은 객체의 소유자에게만 허용
        if hasattr(obj, "user"):
            return obj.user == request.user
        elif hasattr(obj, "author"):
            return obj.author == request.user

        return False


class CanMatchToday(permissions.BasePermission):
    """오늘 매칭 가능한 사용자"""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        # visitor는 접근 불가
        if request.user.role == User.Role.VISITOR:
            return False

        # 매칭 가능 여부 확인
        return request.user.can_match_today()

    message = "오늘의 매칭 횟수를 모두 사용했습니다. 프리미엄으로 업그레이드하세요."

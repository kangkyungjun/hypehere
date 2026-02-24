from rest_framework import permissions


class IsAuthorOrReadOnly(permissions.BasePermission):
    """
    작성자만 수정/삭제 가능
    - 읽기: 누구나 가능 (비회원 포함)
    - 쓰기/수정/삭제: 작성자 or 관리자만 가능
    """

    def has_object_permission(self, request, view, obj):
        # 읽기 권한은 누구에게나 허용 (GET, HEAD, OPTIONS)
        if request.method in permissions.SAFE_METHODS:
            return True

        # 쓰기 권한은 작성자 or 관리자만
        return (obj.author == request.user
                or request.user.is_staff
                or getattr(request.user, 'role', None) in ('master', 'manager'))


class IsAuthenticatedForCommentWrite(permissions.BasePermission):
    """
    댓글 작성은 로그인 필수
    - 비회원: 댓글 조회 가능 (단, 내용은 숨김 처리)
    - 회원: 댓글 조회/작성 가능
    """

    def has_permission(self, request, view):
        # 읽기 권한은 누구에게나 허용 (GET, HEAD, OPTIONS)
        if request.method in permissions.SAFE_METHODS:
            return True

        # 쓰기 권한은 인증된 사용자만
        return request.user and request.user.is_authenticated

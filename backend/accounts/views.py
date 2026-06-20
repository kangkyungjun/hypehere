import json
import logging
from datetime import timedelta

from django.conf import settings as django_settings
from rest_framework import status
from rest_framework.decorators import api_view, authentication_classes, permission_classes, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model
from django.db import transaction
from django.db.models import Q, Max, Count
from django.utils import timezone
from django.utils.dateparse import parse_date

logger = logging.getLogger(__name__)
from .serializers import (
    RegisterSerializer, LoginSerializer, UserSerializer, ChangePasswordSerializer,
    DeviceTokenSerializer, SubscriptionSyncSerializer,
    SendVerificationCodeSerializer, VerifyCodeSerializer, PasswordResetConfirmSerializer,
    InvestmentProfileSerializer, RecommendationSerializer,
)
from .models import DeviceToken, NotificationSubscription, NotificationHistory, SubscriptionInfo, InvestmentProfile, Recommendation
from .email_utils import create_and_send_code, verify_code, send_subscription_email
from .fcm_utils import send_general_to_all, _send_fcm, send_subscription_notification

User = get_user_model()


@api_view(['POST'])
@permission_classes([AllowAny])
def register_view(request):
    """
    회원가입 → {user, token, message}
    이메일 인증 완료 후에만 가입 가능
    Flutter: POST /api/accounts/register/
    """
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']

        # 이메일 인증 완료 여부 확인
        from .models import EmailVerificationCode
        verified = EmailVerificationCode.objects.filter(
            email=email,
            purpose='signup',
            is_used=True,
        ).exists()

        if not verified:
            return Response(
                {'error': '이메일 인증이 완료되지 않았습니다.', 'email_not_verified': True},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = serializer.save()
        user.is_email_verified = True
        user.save(update_fields=['is_email_verified'])

        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'user': UserSerializer(user).data,
            'token': token.key,
            'message': '회원가입이 완료되었습니다.',
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def register_with_verification_view(request):
    """
    인증코드 검증 + 회원가입 원자적 처리
    비밀번호 검증을 먼저 수행하여, 실패 시 인증코드를 소진하지 않음
    Flutter: POST /api/accounts/register-with-verification/
    """
    serializer = RegisterSerializer(data=request.data)
    if not serializer.is_valid():
        # 비밀번호 검증 실패 등 → 인증코드 미소진 상태로 반환
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    email = serializer.validated_data['email']
    code = request.data.get('code', '').strip()

    if not code:
        return Response(
            {'error': '인증코드를 입력해주세요.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # 이미 가입된 이메일 체크
    if User.objects.filter(email=email).exists():
        return Response(
            {'error': '이미 가입된 이메일입니다.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # 인증코드 검증 (여기서 is_used=True로 마킹)
    success, error_type = verify_code(email, code, 'signup')
    if not success:
        error_messages = {
            'not_found': '인증코드를 찾을 수 없습니다. 새 코드를 요청해주세요.',
            'expired': '인증코드가 만료되었습니다. 새 코드를 요청해주세요.',
            'max_attempts': '입력 횟수를 초과했습니다. 새 코드를 요청해주세요.',
            'invalid_code': '인증코드가 올바르지 않습니다.',
        }
        return Response(
            {'error': error_messages.get(error_type, '인증에 실패했습니다.'), 'error_type': error_type},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # 유저 생성 (검증 + 인증코드 모두 통과)
    user = serializer.save()
    user.is_email_verified = True
    user.save(update_fields=['is_email_verified'])

    token, _ = Token.objects.get_or_create(user=user)
    return Response({
        'user': UserSerializer(user).data,
        'token': token.key,
        'message': '회원가입이 완료되었습니다.',
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    """
    로그인 → {user, token, message}
    이메일 미인증 사용자는 403 반환
    Flutter: POST /api/accounts/login/
    """
    serializer = LoginSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        user = serializer.validated_data['user']

        if not user.is_email_verified:
            return Response(
                {'error': '이메일 인증이 완료되지 않았습니다.', 'email_not_verified': True},
                status=status.HTTP_403_FORBIDDEN,
            )

        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'user': UserSerializer(user).data,
            'token': token.key,
            'message': '로그인 성공',
        }, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profile_view(request):
    """
    내 프로필 조회 (role 포함)
    Flutter: GET /api/accounts/profile/
    """
    return Response(UserSerializer(request.user).data)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def update_profile_view(request):
    """
    프로필 수정 (multipart 지원: nickname, bio, profile_picture)
    Flutter: PATCH /api/accounts/update/
    """
    serializer = UserSerializer(
        request.user,
        data=request.data,
        partial=True,
    )
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password_view(request):
    """
    비밀번호 변경 → 기존 Token 삭제 + 새 Token 발급 → {token}
    Flutter: POST /api/accounts/change-password/
    """
    serializer = ChangePasswordSerializer(
        data=request.data,
        context={'request': request},
    )
    if serializer.is_valid():
        request.user.set_password(serializer.validated_data['new_password'])
        request.user.save()

        # 기존 토큰 삭제 + 새 토큰 발급
        Token.objects.filter(user=request.user).delete()
        new_token = Token.objects.create(user=request.user)

        return Response({
            'token': new_token.key,
            'message': '비밀번호가 변경되었습니다.',
        }, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ========================================
# 이메일 인증 API
# ========================================

@api_view(['POST'])
@permission_classes([AllowAny])
def send_verification_code_view(request):
    """
    인증코드 발송
    signup: 이메일 중복 체크 후 발송
    password_reset: 존재 여부 숨김 (항상 200)
    Flutter: POST /api/accounts/verification/send/
    """
    serializer = SendVerificationCodeSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    email = serializer.validated_data['email']
    purpose = serializer.validated_data['purpose']

    if purpose == 'signup':
        # 이미 가입된 이메일 체크
        if User.objects.filter(email=email).exists():
            return Response(
                {'error': '이미 가입된 이메일입니다.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

    if purpose == 'password_reset':
        # email enumeration 방지: 존재하지 않아도 동일 응답
        if not User.objects.filter(email=email).exists():
            return Response({'message': '인증코드가 발송되었습니다.'})

    success, error, cooldown = create_and_send_code(email, purpose)

    if success:
        return Response({'message': '인증코드가 발송되었습니다.'})

    if error == 'cooldown':
        return Response(
            {'error': '잠시 후 다시 시도해주세요.', 'cooldown_remaining': cooldown},
            status=status.HTTP_429_TOO_MANY_REQUESTS,
        )

    return Response(
        {'error': '이메일 발송에 실패했습니다. 잠시 후 다시 시도해주세요.'},
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )


@api_view(['POST'])
@permission_classes([AllowAny])
def verify_code_view(request):
    """
    인증코드 확인
    Flutter: POST /api/accounts/verification/verify/
    """
    serializer = VerifyCodeSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    email = serializer.validated_data['email']
    code = serializer.validated_data['code']
    purpose = serializer.validated_data['purpose']

    success, error_type = verify_code(email, code, purpose)

    if success:
        return Response({'message': '인증이 완료되었습니다.', 'verified': True})

    error_messages = {
        'not_found': '인증코드를 찾을 수 없습니다. 새 코드를 요청해주세요.',
        'expired': '인증코드가 만료되었습니다. 새 코드를 요청해주세요.',
        'max_attempts': '입력 횟수를 초과했습니다. 새 코드를 요청해주세요.',
        'invalid_code': '인증코드가 올바르지 않습니다.',
    }

    return Response(
        {'error': error_messages.get(error_type, '인증에 실패했습니다.'), 'error_type': error_type},
        status=status.HTTP_400_BAD_REQUEST,
    )


@api_view(['POST'])
@permission_classes([AllowAny])
def password_reset_request_view(request):
    """
    비밀번호 재설정 코드 발송 (send_verification_code_view의 래퍼)
    email enumeration 방지: 항상 200 반환
    Flutter: POST /api/accounts/password-reset/request/
    """
    email = (request.data.get('email') or '').strip()
    if not email:
        return Response(
            {'error': '이메일을 입력해주세요.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # 존재하지 않는 이메일이어도 동일 응답
    if not User.objects.filter(email=email).exists():
        return Response({'message': '인증코드가 발송되었습니다.'})

    success, error, cooldown = create_and_send_code(email, 'password_reset')

    if success:
        return Response({'message': '인증코드가 발송되었습니다.'})

    if error == 'cooldown':
        return Response(
            {'error': '잠시 후 다시 시도해주세요.', 'cooldown_remaining': cooldown},
            status=status.HTTP_429_TOO_MANY_REQUESTS,
        )

    return Response(
        {'error': '이메일 발송에 실패했습니다. 잠시 후 다시 시도해주세요.'},
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )


@api_view(['POST'])
@permission_classes([AllowAny])
def password_reset_confirm_view(request):
    """
    코드 검증 + 새 비밀번호 설정 + 기존 토큰 삭제
    Flutter: POST /api/accounts/password-reset/confirm/
    """
    serializer = PasswordResetConfirmSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    email = serializer.validated_data['email']
    code = serializer.validated_data['code']
    new_password = serializer.validated_data['new_password']

    # 코드 검증
    success, error_type = verify_code(email, code, 'password_reset')
    if not success:
        error_messages = {
            'not_found': '인증코드를 찾을 수 없습니다. 새 코드를 요청해주세요.',
            'expired': '인증코드가 만료되었습니다. 새 코드를 요청해주세요.',
            'max_attempts': '입력 횟수를 초과했습니다. 새 코드를 요청해주세요.',
            'invalid_code': '인증코드가 올바르지 않습니다.',
        }
        return Response(
            {'error': error_messages.get(error_type, '인증에 실패했습니다.'), 'error_type': error_type},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # 비밀번호 변경
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({'message': '비밀번호가 재설정되었습니다.'})

    user.set_password(new_password)
    user.save(update_fields=['password'])

    # 기존 토큰 전부 삭제 (전 기기 로그아웃)
    Token.objects.filter(user=user).delete()

    return Response({'message': '비밀번호가 재설정되었습니다. 새 비밀번호로 로그인해주세요.'})


# ========================================
# 회원탈퇴 API
# ========================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def request_deletion_view(request):
    """
    회원탈퇴 요청 (7일 유예기간)
    Flutter: POST /api/accounts/request-deletion/
    """
    user = request.user

    if user.deletion_requested_at:
        return Response(
            {'error': '이미 삭제가 예약되어 있습니다'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user.deletion_requested_at = timezone.now()
    user.save(update_fields=['deletion_requested_at'])

    grace_days = user.DELETION_GRACE_DAYS
    deletion_date = user.deletion_requested_at + timedelta(days=grace_days)

    return Response({
        'message': f'계정 탈퇴가 예약되었습니다. {grace_days}일 후 영구 삭제됩니다.',
        'deletion_date': deletion_date,
        'days_remaining': grace_days,
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def cancel_deletion_view(request):
    """
    회원탈퇴 취소
    Flutter: POST /api/accounts/cancel-deletion/
    """
    user = request.user

    if not user.deletion_requested_at:
        return Response(
            {'error': '삭제 요청이 없습니다'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user.deletion_requested_at = None
    user.save(update_fields=['deletion_requested_at'])

    return Response({'message': '탈퇴 요청이 취소되었습니다.'})


# ========================================
# 권한 관리 API (Manager/Master 전용)
# ========================================

_USER_ROLES = ('master', 'manager', 'gold', 'regular')
_USER_PAGE_SIZE_DEFAULT = 20
_USER_PAGE_SIZE_MAX = 100


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_users_view(request):
    """
    사용자 목록/검색 (Manager+ 전용, 페이지네이션).

    Query:
        q      : 이메일/닉네임 부분일치 (선택)
        role   : master|manager|gold|regular 단일 필터 (선택)
        page   : 1-based (기본 1)
        size   : 페이지 크기 (기본 20, 최대 100)

    응답 (DRF 호환):
        { count, next, previous, results: [...] }
        next/previous 는 URL 또는 null (Flutter는 next != null 만 사용)
    """
    if request.user.role not in ('master', 'manager'):
        return Response(
            {'detail': '권한이 없습니다. Manager 이상만 접근 가능합니다.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    query = request.query_params.get('q', '').strip()
    role_filter = (request.query_params.get('role') or '').strip().lower()

    try:
        page = max(1, int(request.query_params.get('page', '1')))
    except ValueError:
        page = 1
    try:
        size = int(request.query_params.get('size', str(_USER_PAGE_SIZE_DEFAULT)))
    except ValueError:
        size = _USER_PAGE_SIZE_DEFAULT
    size = max(1, min(size, _USER_PAGE_SIZE_MAX))

    qs = User.objects.all()
    if query:
        qs = qs.filter(Q(email__icontains=query) | Q(nickname__icontains=query))
    if role_filter in _USER_ROLES:
        qs = qs.filter(role=role_filter)
    qs = qs.order_by('-date_joined', '-id')

    total = qs.count()
    start = (page - 1) * size
    end = start + size
    items = list(qs[start:end])
    has_next = end < total

    def _page_url(p):
        base = request.build_absolute_uri(request.path)
        parts = [f'page={p}', f'size={size}']
        if query:
            parts.append(f'q={query}')
        if role_filter in _USER_ROLES:
            parts.append(f'role={role_filter}')
        return f'{base}?{"&".join(parts)}'

    return Response({
        'count': total,
        'page': page,
        'size': size,
        'next': _page_url(page + 1) if has_next else None,
        'previous': _page_url(page - 1) if page > 1 else None,
        'results': UserSerializer(items, many=True).data,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def users_stats_view(request):
    """
    사용자 권한 분포 통계 (Manager+ 전용).
    Flutter: GET /api/accounts/users/stats/

    응답: { total, master, manager, gold, regular }
    """
    if request.user.role not in ('master', 'manager'):
        return Response(
            {'detail': '권한이 없습니다.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    counts = dict.fromkeys(_USER_ROLES, 0)
    rows = (
        User.objects.values('role')
        .annotate(n=Count('id'))
        .values_list('role', 'n')
    )
    for r, n in rows:
        if r in counts:
            counts[r] = n

    return Response({
        'total': sum(counts.values()),
        **counts,
    })


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def promote_to_gold_view(request, pk):
    """
    Gold로 승급 (Manager+ 전용)
    Flutter: PATCH /api/accounts/users/<id>/promote-to-gold/
    """
    if request.user.role not in ('master', 'manager'):
        return Response(
            {'detail': '권한이 없습니다. Manager 이상만 Gold로 승급할 수 있습니다.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    try:
        target_user = User.objects.get(pk=pk)
    except User.DoesNotExist:
        return Response(
            {'error': '사용자를 찾을 수 없습니다.'},
            status=status.HTTP_404_NOT_FOUND,
        )

    if target_user.role in ('master', 'manager'):
        return Response(
            {'error': f'이미 {target_user.get_role_display()} 등급입니다.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    target_user.role = 'gold'
    target_user.save(update_fields=['role'])

    return Response({
        'message': f'{target_user.nickname}님이 Gold로 승급되었습니다.',
        'user': UserSerializer(target_user).data,
    })


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def promote_to_manager_view(request, pk):
    """
    Manager로 승급 (Master 전용)
    Flutter: PATCH /api/accounts/users/<id>/promote-to-manager/
    """
    if request.user.role != 'master':
        return Response(
            {'detail': '권한이 없습니다. Master만 Manager로 승급할 수 있습니다.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    try:
        target_user = User.objects.get(pk=pk)
    except User.DoesNotExist:
        return Response(
            {'error': '사용자를 찾을 수 없습니다.'},
            status=status.HTTP_404_NOT_FOUND,
        )

    if target_user.role == 'master':
        return Response(
            {'error': '이미 Master 등급입니다.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    target_user.role = 'manager'
    target_user.save(update_fields=['role'])

    return Response({
        'message': f'{target_user.nickname}님이 Manager로 승급되었습니다.',
        'user': UserSerializer(target_user).data,
    })


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def demote_to_regular_view(request, pk):
    """
    Regular로 강등 (Manager+: Gold 강등 / Master: Manager 강등)
    Flutter: PATCH /api/accounts/users/<id>/demote-to-regular/
    """
    if request.user.role not in ('master', 'manager'):
        return Response(
            {'error': '권한이 없습니다. Manager 이상만 강등할 수 있습니다.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    try:
        target_user = User.objects.get(pk=pk)
    except User.DoesNotExist:
        return Response(
            {'error': '사용자를 찾을 수 없습니다.'},
            status=status.HTTP_404_NOT_FOUND,
        )

    if target_user.role == 'master':
        return Response(
            {'error': 'Master는 강등할 수 없습니다.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if target_user.role == 'manager' and request.user.role != 'master':
        return Response(
            {'error': 'Manager 강등은 Master만 가능합니다.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    if target_user.role == 'regular':
        return Response(
            {'error': '이미 Regular 등급입니다.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    target_user.role = 'regular'
    target_user.save(update_fields=['role'])

    return Response({
        'message': f'{target_user.nickname}님이 Regular로 강등되었습니다.',
        'user': UserSerializer(target_user).data,
    })


# ========================================
# FCM 디바이스 토큰 API
# ========================================

@api_view(['POST'])
@permission_classes([AllowAny])
def device_register_view(request):
    """
    FCM 토큰 등록/갱신 (비로그인 사용자도 가능)
    Flutter: POST /api/accounts/device/register/ {token, platform, language}
    """
    serializer = DeviceTokenSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    token = serializer.validated_data['token']
    platform = serializer.validated_data['platform']
    language = serializer.validated_data.get('language', 'en')

    user = request.user if request.user.is_authenticated else None

    if user:
        # 로그인 사용자: 같은 토큰이 다른 사용자에게 있으면 비활성화
        DeviceToken.objects.filter(token=token).exclude(user=user).update(is_active=False)

    # UPSERT: 토큰 있으면 갱신, 없으면 생성
    obj, created = DeviceToken.objects.update_or_create(
        token=token,
        defaults={'user': user, 'platform': platform, 'language': language, 'is_active': True},
    )

    if user:
        # 같은 사용자 + 같은 플랫폼의 이전 토큰 비활성화 (중복 알림 방지)
        stale = DeviceToken.objects.filter(
            user=user, platform=platform, is_active=True
        ).exclude(pk=obj.pk).update(is_active=False)
        if stale:
            logger.info(f"Deactivated {stale} stale token(s) for user {user.id} ({platform})")

        # 다른 플랫폼 토큰 언어도 동기화 (일관된 언어로 알림 발송)
        DeviceToken.objects.filter(
            user=user, is_active=True
        ).exclude(pk=obj.pk).update(language=language)

    return Response({'message': '토큰 등록 완료', 'created': created})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def device_deactivate_view(request):
    """
    로그아웃 시 FCM 토큰 비활성화
    Flutter: POST /api/accounts/device/deactivate/ {token}
    """
    token = request.data.get('token')
    if not token:
        return Response({'error': 'token 필수'}, status=status.HTTP_400_BAD_REQUEST)

    updated = DeviceToken.objects.filter(
        user=request.user, token=token
    ).update(is_active=False)

    return Response({'message': '토큰 비활성화 완료', 'deactivated': updated > 0})


@api_view(['PUT', 'GET'])
@permission_classes([IsAuthenticated])
def device_subscriptions_view(request):
    """
    Watchlist 구독 동기화
    GET: 현재 구독 목록
    PUT: watchlist와 동기화 {tickers: ["AAPL", "TSLA", ...]}
    """
    if request.method == 'GET':
        tickers = list(
            NotificationSubscription.objects.filter(
                user=request.user, is_active=True
            ).values_list('ticker', flat=True)
        )
        return Response({'tickers': tickers})

    # PUT
    serializer = SubscriptionSyncSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    new_tickers = set(t.upper() for t in serializer.validated_data['tickers'])

    # 기존 구독 전부 비활성화
    NotificationSubscription.objects.filter(user=request.user).update(is_active=False)

    # 새 목록으로 UPSERT
    for ticker in new_tickers:
        NotificationSubscription.objects.update_or_create(
            user=request.user, ticker=ticker,
            defaults={'is_active': True},
        )

    return Response({'message': '구독 동기화 완료', 'tickers': sorted(new_tickers)})


# ========================================
# 푸시 알림 브로드캐스트 API (Manager+ 전용)
# ========================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def broadcast_push_view(request):
    """
    전체 사용자에게 커스텀 푸시 알림 발송 (Manager+ 전용)
    Flutter: POST /api/accounts/push/broadcast/
    {title, body}
    """
    if request.user.role not in ('master', 'manager'):
        return Response(
            {'detail': '권한이 없습니다. Manager 이상만 발송할 수 있습니다.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    title = (request.data.get('title') or '').strip()
    body = (request.data.get('body') or '').strip()

    if not title or not body:
        return Response(
            {'error': 'title과 body는 필수입니다.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if len(title) > 100:
        return Response(
            {'error': 'title은 100자 이내여야 합니다.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if len(body) > 500:
        return Response(
            {'error': 'body는 500자 이내여야 합니다.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # 전체 활성 토큰 조회 (rate limit 무시 — 관리자 수동 발송)
    tokens = list(
        DeviceToken.objects.filter(is_active=True).values_list('token', flat=True)
    )

    if not tokens:
        return Response({'message': '활성 디바이스가 없습니다.', 'sent': 0})

    success, failure, invalid = _send_fcm(
        tokens, title, body,
        data={'type': 'ADMIN_BROADCAST'},
    )

    # 전체 활성 사용자에게 알림 이력 저장 (비로그인 user_id=NULL 제외)
    users = DeviceToken.objects.filter(
        is_active=True, user_id__isnull=False,
    ).values_list('user_id', flat=True).distinct()
    history_objs = [
        NotificationHistory(
            user_id=uid, title=title, body=body,
            notification_type='ADMIN_BROADCAST', ticker='',
        )
        for uid in users
    ]
    NotificationHistory.objects.bulk_create(history_objs, ignore_conflicts=True)

    return Response({
        'message': f'발송 완료: 성공 {success}, 실패 {failure}',
        'sent': success,
        'failed': failure,
        'total_devices': len(tokens),
    })


# ========================================
# 알림 인박스 API
# ========================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def notification_history_view(request):
    """
    최근 7일 알림 목록 반환
    Flutter: GET /api/accounts/notifications/
    """
    cutoff = timezone.now() - timedelta(days=7)
    notifications = NotificationHistory.objects.filter(
        user=request.user,
        created_at__gte=cutoff,
    ).order_by('-created_at')[:100]

    unread_count = NotificationHistory.objects.filter(
        user=request.user,
        is_read=False,
        created_at__gte=cutoff,
    ).count()

    data = [
        {
            'id': n.id,
            'title': n.title,
            'body': n.body,
            'notification_type': n.notification_type,
            'ticker': n.ticker,
            'post_id': n.post_id,
            'is_read': n.is_read,
            'created_at': n.created_at.isoformat(),
        }
        for n in notifications
    ]

    return Response({
        'notifications': data,
        'unread_count': unread_count,
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def notification_mark_read_view(request):
    """
    전체 알림 읽음 처리
    Flutter: POST /api/accounts/notifications/read/
    """
    updated = NotificationHistory.objects.filter(
        user=request.user,
        is_read=False,
    ).update(is_read=True)

    return Response({'marked_read': updated})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def notification_mark_single_read_view(request, pk):
    """
    개별 알림 읽음 처리
    Flutter: POST /api/accounts/notifications/<id>/read/
    """
    updated = NotificationHistory.objects.filter(
        id=pk,
        user=request.user,
        is_read=False,
    ).update(is_read=True)

    return Response({'marked_read': updated})


# ========================================
# 투자 프로필 API
# ========================================

@api_view(['GET', 'POST', 'PUT'])
@permission_classes([IsAuthenticated])
def investment_profile_view(request):
    """
    투자 프로필 조회/생성/수정
    GET  → 프로필 조회 (없으면 404)
    POST/PUT → upsert (get_or_create + partial update)
    Flutter: /api/accounts/investment-profile/
    """
    if request.method == 'GET':
        try:
            profile = request.user.investment_profile
            return Response(InvestmentProfileSerializer(profile).data)
        except InvestmentProfile.DoesNotExist:
            return Response(
                {'detail': 'Investment profile not set.'},
                status=status.HTTP_404_NOT_FOUND,
            )

    # POST / PUT → upsert
    profile, created = InvestmentProfile.objects.get_or_create(user=request.user)
    serializer = InvestmentProfileSerializer(profile, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@authentication_classes([])
@permission_classes([AllowAny])
def internal_user_profiles_view(request):
    """
    Mac mini 내부 API — 전체 투자 프로필 조회
    X-API-Key 헤더 검증 (RevenueCat webhook과 동일한 패턴)
    GET /api/v1/internal/users/profiles/
    """
    api_key = request.headers.get('X-API-Key', '')
    expected_key = django_settings.INTERNAL_API_KEY
    if not expected_key or api_key != expected_key:
        return Response({'error': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)

    profiles = InvestmentProfile.objects.select_related('user').all()

    # 유저별 언어 (active DeviceToken 기준; 등록 시 기기 간 동기화되어 단일 값이 일반적)
    # email_utils.send_subscription_email()와 동일한 해석 패턴. 미설정 시 'en'.
    device_langs = dict(
        DeviceToken.objects.filter(is_active=True).values_list('user_id', 'language')
    )

    data = []
    for p in profiles:
        data.append({
            'user_id': p.user_id,
            'email': p.user.email,
            'nickname': p.user.nickname,
            'role': p.user.role,
            'investment_style': p.investment_style,
            'time_horizon': p.time_horizon,
            'risk_tolerance': p.risk_tolerance,
            'target_return': p.target_return,
            'max_loss_tolerance': p.max_loss_tolerance,
            'language': device_langs.get(p.user_id, 'en'),
            'updated_at': p.updated_at.isoformat(),
        })

    return Response({'profiles': data, 'count': len(data)})


@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
def ingest_recommendations_view(request):
    """
    Mac mini 내부 API — 유저별 추천종목 배치 업로드 (Phase C)
    X-API-Key 헤더 검증. 같은 date 재업로드 시 해당 날짜 전체 삭제 후 재삽입(멱등).
    POST /api/v1/internal/ingest/recommendations
    Body: {"date": "YYYY-MM-DD", "recommendations": [{user_id, rank, ticker, fit_score,
           rationale_json, name, name_ko, current_price, change_pct, signal}, ...]}
    """
    api_key = request.headers.get('X-API-Key', '')
    expected_key = django_settings.INTERNAL_API_KEY
    if not expected_key or api_key != expected_key:
        return Response({'error': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)

    date_str = request.data.get('date')
    items = request.data.get('recommendations', [])
    if not date_str or not isinstance(items, list):
        return Response({'error': 'date and recommendations[] required.'},
                        status=status.HTTP_400_BAD_REQUEST)
    rec_date = parse_date(date_str)
    if rec_date is None:
        return Response({'error': 'Invalid date (expected YYYY-MM-DD).'},
                        status=status.HTTP_400_BAD_REQUEST)

    # user_id 정수 변환 (비숫자/None 은 건너뜀 — 배치 전체 실패 방지)
    def _to_int(v):
        try:
            return int(v)
        except (TypeError, ValueError):
            return None

    requested_ids = {iid for iid in (_to_int(it.get('user_id')) for it in items) if iid is not None}
    valid_ids = set(User.objects.filter(id__in=requested_ids).values_list('id', flat=True))

    objs = []
    skipped = 0
    for it in items:
        uid = _to_int(it.get('user_id'))
        ticker = it.get('ticker')
        if uid is None or uid not in valid_ids or not ticker:
            skipped += 1
            continue
        objs.append(Recommendation(
            user_id=uid,
            date=rec_date,
            rank=it.get('rank') or 0,
            ticker=ticker,
            fit_score=it.get('fit_score') or 0.0,
            rationale_json=it.get('rationale_json') or {},
            name=it.get('name') or '',
            name_ko=it.get('name_ko') or '',
            current_price=it.get('current_price'),
            change_pct=it.get('change_pct'),
            signal=it.get('signal') or '',
        ))

    with transaction.atomic():
        Recommendation.objects.filter(date=rec_date).delete()
        Recommendation.objects.bulk_create(objs, ignore_conflicts=True)

    return Response({
        'ingested': len(objs),
        'skipped': skipped,
        'users': len({o.user_id for o in objs}),
        'date': date_str,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_recommendations_view(request):
    """
    앱 — 본인 추천종목 조회 (Phase C)
    GET /api/v1/users/me/recommendations?date=YYYY-MM-DD
    date 미지정 시 본인 최신 날짜. 추천 없으면 빈 배열(graceful).
    """
    date_str = request.query_params.get('date')
    qs = Recommendation.objects.filter(user=request.user)

    if date_str:
        rec_date = parse_date(date_str)
        if rec_date is None:
            return Response({'error': 'Invalid date (expected YYYY-MM-DD).'},
                            status=status.HTTP_400_BAD_REQUEST)
    else:
        rec_date = qs.aggregate(latest=Max('date'))['latest']

    if rec_date is None:
        return Response({'date': None, 'style': None, 'recommendations': []})

    recs = qs.filter(date=rec_date).order_by('rank')

    style = None
    try:
        style = request.user.investment_profile.investment_style
    except InvestmentProfile.DoesNotExist:
        pass

    return Response({
        'date': rec_date.isoformat(),
        'style': style,
        'recommendations': RecommendationSerializer(recs, many=True).data,
    })


# ========================================
# RevenueCat IAP Webhook + Subscription API
# ========================================

@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
def revenuecat_webhook_view(request):
    """
    RevenueCat webhook 수신 → SubscriptionInfo 업데이트 + role 승급/강등
    URL: POST /api/marketlens/accounts/webhook/revenuecat/
    """
    # Bearer 토큰 검증
    auth_header = request.headers.get('Authorization', '')
    expected = f'Bearer {django_settings.REVENUECAT_WEBHOOK_SECRET}'
    if not django_settings.REVENUECAT_WEBHOOK_SECRET or auth_header != expected:
        return Response({'error': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)

    try:
        body = request.data if isinstance(request.data, dict) else json.loads(request.body)
        event = body.get('event', {})
    except (json.JSONDecodeError, Exception):
        return Response({'error': 'Invalid JSON'}, status=status.HTTP_400_BAD_REQUEST)

    event_type = event.get('type', '')
    app_user_id = event.get('app_user_id', '')
    product_id = event.get('product_id', '')
    store = event.get('store', '')
    period_type = event.get('period_type', '')  # 'TRIAL' | 'NORMAL' | 'INTRO'
    expiration_at_ms = event.get('expiration_at_ms')
    purchase_at_ms = event.get('original_purchase_date_ms') or event.get('purchased_at_ms')

    if not app_user_id:
        return Response({'error': 'Missing app_user_id'}, status=status.HTTP_400_BAD_REQUEST)

    # app_user_id = Django user PK (문자열)
    try:
        user = User.objects.get(pk=int(app_user_id))
    except (User.DoesNotExist, ValueError):
        logger.warning(f'[RevenueCat] User not found: {app_user_id}')
        return Response({'ok': True})  # RevenueCat에 200 반환 (재시도 방지)

    # SubscriptionInfo upsert
    sub, _ = SubscriptionInfo.objects.get_or_create(user=user)
    sub.revenuecat_app_user_id = app_user_id
    sub.last_webhook_event = event_type
    sub.last_webhook_at = timezone.now()

    if product_id:
        sub.product_id = product_id
    if store:
        sub.store = store

    if expiration_at_ms:
        from datetime import datetime as dt, timezone as tz
        sub.expiration_date = dt.fromtimestamp(
            int(expiration_at_ms) / 1000, tz=tz.utc,
        )

    if purchase_at_ms and not sub.original_purchase_date:
        from datetime import datetime as dt, timezone as tz
        sub.original_purchase_date = dt.fromtimestamp(
            int(purchase_at_ms) / 1000, tz=tz.utc,
        )

    activate_events = {'INITIAL_PURCHASE', 'RENEWAL', 'UNCANCELLATION', 'NON_RENEWING_PURCHASE'}
    deactivate_events = {'CANCELLATION', 'EXPIRATION', 'BILLING_ISSUE'}

    # 만료일 포맷 (알림 메시지용)
    expiration_str = ''
    if sub.expiration_date:
        expiration_str = sub.expiration_date.strftime('%Y-%m-%d')

    if event_type in activate_events:
        sub.is_active = True
        sub.unsubscribe_detected_at = None

        # Trial 처리
        if event_type == 'INITIAL_PURCHASE' and period_type == 'TRIAL':
            sub.is_trial = True
            sub.has_used_trial = True  # 영구 플래그 — 재체험 방지
            sub.trial_started_at = timezone.now()
            logger.info(f'[RevenueCat] {user.email} started free trial')
        elif event_type == 'RENEWAL':
            sub.is_trial = False  # 체험→유료 전환 완료

        if user.role == 'regular':
            user.role = 'gold'
            user.save(update_fields=['role'])
            logger.info(f'[RevenueCat] {user.email} upgraded to gold via {event_type}')

        # FCM + 이메일 알림 발송
        if event_type in ('INITIAL_PURCHASE', 'RENEWAL'):
            store_name = 'App Store' if store == 'APP_STORE' else 'Google Play'
            notification_ctx = {'expiration_date': expiration_str, 'store': store_name}
            try:
                send_subscription_notification(user, event_type, context=notification_ctx)
            except Exception as e:
                logger.error(f'[RevenueCat] FCM error for {event_type}: {e}')
            try:
                send_subscription_email(user, event_type, context=notification_ctx)
            except Exception as e:
                logger.error(f'[RevenueCat] Email error for {event_type}: {e}')

    elif event_type in deactivate_events:
        sub.is_active = False
        sub.is_trial = False  # 만료/취소 시 체험 상태도 해제
        if event_type == 'CANCELLATION':
            sub.unsubscribe_detected_at = timezone.now()
        # IAP로 승급된 Gold만 강등 (수동 승급 Gold 보호 — webhook 자동 강등만 차단)
        if user.role == 'gold' and sub.original_purchase_date is not None:
            user.role = 'regular'
            user.save(update_fields=['role'])
            logger.info(f'[RevenueCat] {user.email} downgraded to regular via {event_type}')

        # FCM + 이메일 알림 발송
        notification_ctx = {'expiration_date': expiration_str}
        try:
            send_subscription_notification(user, event_type, context=notification_ctx)
        except Exception as e:
            logger.error(f'[RevenueCat] FCM error for {event_type}: {e}')
        if event_type == 'EXPIRATION':
            try:
                send_subscription_email(user, event_type, context=notification_ctx)
            except Exception as e:
                logger.error(f'[RevenueCat] Email error for {event_type}: {e}')

    elif event_type == 'TRANSFER':
        # 구독이 다른 app_user_id로 이동할 때
        transferred_from = event.get('transferred_from', [''])[0] if isinstance(event.get('transferred_from'), list) else event.get('transferred_from', '')
        transferred_to = event.get('transferred_to', [''])[0] if isinstance(event.get('transferred_to'), list) else event.get('transferred_to', '')

        # 이전 소유자에게 알림
        if transferred_from:
            try:
                old_user = User.objects.get(pk=int(transferred_from))
                send_subscription_notification(old_user, 'TRANSFER_OUT')
            except (User.DoesNotExist, ValueError, Exception) as e:
                logger.warning(f'[RevenueCat] TRANSFER_OUT notification failed: {e}')

        # 새 소유자에게 알림
        if transferred_to:
            try:
                new_user = User.objects.get(pk=int(transferred_to))
                send_subscription_notification(new_user, 'TRANSFER_IN')
            except (User.DoesNotExist, ValueError, Exception) as e:
                logger.warning(f'[RevenueCat] TRANSFER_IN notification failed: {e}')

        logger.info(f'[RevenueCat] TRANSFER: {transferred_from} → {transferred_to}')

    sub.save()
    return Response({'ok': True})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def subscription_status_view(request):
    """
    현재 유저의 구독 상태 조회
    GET /api/marketlens/accounts/subscription/status/
    """
    try:
        sub = request.user.subscription
        return Response({
            'is_active': sub.is_active,
            'product_id': sub.product_id,
            'store': sub.store,
            'expiration_date': sub.expiration_date.isoformat() if sub.expiration_date else None,
            'is_iap_gold': sub.original_purchase_date is not None,
            'is_trial': sub.is_trial,
            'has_used_trial': sub.has_used_trial,
        })
    except SubscriptionInfo.DoesNotExist:
        return Response({
            'is_active': False,
            'product_id': '',
            'store': '',
            'expiration_date': None,
            'is_iap_gold': False,
            'is_trial': False,
            'has_used_trial': False,
        })


@api_view(['POST'])
@permission_classes([AllowAny])
def report_ad_failure_view(request):
    """클라이언트의 광고 로드 실패 보고 → owner/매니저에게 알림 + owner 이메일.

    POST body: { error, platform, app_version, ad_unit }
    인증 불필요(AllowAny). 스팸 방지(throttle)는 ops_alerts.notify_ad_failure가 담당.
    항상 200을 반환한다 (클라이언트는 fire-and-forget).
    """
    from .ops_alerts import notify_ad_failure

    data = request.data if isinstance(request.data, dict) else {}
    try:
        notify_ad_failure(
            error_message=str(data.get('error', ''))[:500],
            platform=str(data.get('platform', ''))[:20],
            app_version=str(data.get('app_version', ''))[:30],
            ad_unit=str(data.get('ad_unit', ''))[:100],
        )
    except Exception as exc:  # noqa: BLE001
        logging.getLogger(__name__).error(f'[report_ad_failure] {exc}')
    return Response({'ok': True})

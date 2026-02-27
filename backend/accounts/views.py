from datetime import timedelta

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model
from django.db.models import Q
from django.utils import timezone
from .serializers import (
    RegisterSerializer, LoginSerializer, UserSerializer, ChangePasswordSerializer,
    DeviceTokenSerializer, SubscriptionSyncSerializer,
)
from .models import DeviceToken, NotificationSubscription, NotificationHistory
from .fcm_utils import send_general_to_all, _send_fcm

User = get_user_model()


@api_view(['POST'])
@permission_classes([AllowAny])
def register_view(request):
    """
    회원가입 → {user, token, message}
    Flutter: POST /api/accounts/register/
    """
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'user': UserSerializer(user).data,
            'token': token.key,
            'message': '회원가입이 완료되었습니다.',
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    """
    로그인 → {user, token, message}
    Flutter: POST /api/accounts/login/
    """
    serializer = LoginSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        user = serializer.validated_data['user']
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

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_users_view(request):
    """
    사용자 검색 (Manager+ 전용)
    Flutter: GET /api/accounts/users/search/?q=<query>
    """
    if request.user.role not in ('master', 'manager'):
        return Response(
            {'detail': '권한이 없습니다. Manager 이상만 접근 가능합니다.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    query = request.query_params.get('q', '').strip()
    if not query:
        return Response([])

    users = User.objects.filter(
        Q(email__icontains=query) | Q(nickname__icontains=query)
    )[:20]

    return Response(UserSerializer(users, many=True).data)


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
@permission_classes([IsAuthenticated])
def device_register_view(request):
    """
    FCM 토큰 등록/갱신
    Flutter: POST /api/accounts/device/register/ {token, platform}
    """
    serializer = DeviceTokenSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    token = serializer.validated_data['token']
    platform = serializer.validated_data['platform']
    language = serializer.validated_data.get('language', 'en')

    # 같은 토큰이 다른 사용자에게 있으면 비활성화
    DeviceToken.objects.filter(token=token).exclude(user=request.user).update(is_active=False)

    # UPSERT: 토큰 있으면 갱신, 없으면 생성
    obj, created = DeviceToken.objects.update_or_create(
        token=token,
        defaults={'user': request.user, 'platform': platform, 'language': language, 'is_active': True},
    )

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

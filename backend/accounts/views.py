from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model
from django.db.models import Q
from .serializers import (
    RegisterSerializer, LoginSerializer, UserSerializer, ChangePasswordSerializer
)

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

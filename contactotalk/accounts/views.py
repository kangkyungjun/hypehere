from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import login
from django.utils import timezone
from django.db.models import Q

from .models import User, Interest
from .serializers import (
    RegisterSerializer,
    LoginSerializer,
    UserSerializer,
    ProfileUpdateSerializer,
    ChangePasswordSerializer,
    InterestSerializer,
)


class RegisterAPIView(generics.CreateAPIView):
    """회원가입 API"""

    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # JWT 토큰 생성
        refresh = RefreshToken.for_user(user)

        return Response(
            {
                "message": "회원가입이 완료되었습니다.",
                "user": UserSerializer(user).data,
                "tokens": {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                },
            },
            status=status.HTTP_201_CREATED,
        )


class LoginAPIView(APIView):
    """로그인 API"""

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(
            data=request.data, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)

        user = serializer.validated_data["user"]
        login(request, user)

        # JWT 토큰 생성
        refresh = RefreshToken.for_user(user)

        return Response(
            {
                "message": "로그인되었습니다.",
                "user": UserSerializer(user).data,
                "tokens": {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                },
            },
            status=status.HTTP_200_OK,
        )


class ProfileAPIView(APIView):
    """프로필 조회 API"""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """현재 로그인한 사용자 정보 조회"""
        serializer = UserSerializer(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)


class ProfileUpdateAPIView(generics.UpdateAPIView):
    """프로필 수정 API"""

    serializer_class = ProfileUpdateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)

        return Response(
            {
                "message": "프로필이 수정되었습니다.",
                "user": UserSerializer(instance).data,
            },
            status=status.HTTP_200_OK,
        )


class ChangePasswordAPIView(APIView):
    """비밀번호 변경 API"""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(
            data=request.data, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()

        return Response(
            {"message": "비밀번호가 변경되었습니다."},
            status=status.HTTP_200_OK,
        )


class InterestListAPIView(generics.ListAPIView):
    """관심사 목록 조회 API"""

    queryset = Interest.objects.all()
    serializer_class = InterestSerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = None  # 페이지네이션 비활성화

    def get_queryset(self):
        """카테고리별 필터링"""
        queryset = Interest.objects.all()
        category = self.request.query_params.get("category", None)
        if category:
            queryset = queryset.filter(category=category)
        return queryset


class UserDetailAPIView(generics.RetrieveAPIView):
    """다른 사용자 프로필 조회 API"""

    queryset = User.objects.filter(is_active=True, is_banned=False)
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = "id"


@api_view(["GET"])
@permission_classes([permissions.IsAuthenticated])
def check_match_limit(request):
    """오늘 매칭 가능 여부 확인 API"""
    user = request.user

    return Response(
        {
            "can_match": user.can_match_today(),
            "daily_count": user.daily_match_count,
            "role": user.role,
            "is_premium": user.is_premium_active(),
        },
        status=status.HTTP_200_OK,
    )


class UserStatsAPIView(APIView):
    """사용자 활동 통계 조회 API"""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """사용자의 활동 통계 반환"""
        from chat.models import ChatRoom, OpenChatParticipant, MatchHistory

        user = request.user
        today = timezone.now().date()

        # 오늘의 1:1 매칭 횟수 (나간 방 포함)
        today_match_count = MatchHistory.objects.filter(
            user=user,
            matched_at__date=today
        ).count()

        # 참여 중인 오픈 채팅방 개수
        open_chat_count = OpenChatParticipant.objects.filter(
            user=user
        ).count()

        return Response(
            {
                "today_match_count": today_match_count,
                "open_chat_count": open_chat_count,
            },
            status=status.HTTP_200_OK,
        )


class LogoutAPIView(APIView):
    """로그아웃 API - 매칭 큐 및 채팅방 정리"""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        from django.db import transaction
        from chat.models import MatchingQueue, ChatRoom

        user = request.user

        # 트랜잭션으로 안전하게 처리
        with transaction.atomic():
            # 1. 매칭 큐에서 제거
            MatchingQueue.objects.filter(user=user).delete()

            # 2. 참여 중인 모든 1:1 채팅방 정리
            user_rooms = ChatRoom.objects.filter(
                Q(user1=user) | Q(user2=user),
                is_active=True
            )

            for room in user_rooms:
                # 상대방도 매칭 큐에서 제거
                other_user = room.user1 if room.user2 == user else room.user2
                MatchingQueue.objects.filter(user=other_user).delete()

                # 채팅방 삭제
                room.delete()

        return Response(
            {"message": "로그아웃되었습니다."},
            status=status.HTTP_200_OK,
        )


@api_view(["GET"])
@permission_classes([permissions.AllowAny])
def health_check(request):
    """헬스 체크 API"""
    return Response(
        {
            "status": "healthy",
            "message": "ConTacToTalk API is running",
        },
        status=status.HTTP_200_OK,
    )

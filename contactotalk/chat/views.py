from rest_framework import status, generics, permissions, serializers
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q
from django.shortcuts import get_object_or_404

from accounts.permissions import IsUser, IsNotBanned, CanMatchToday
from accounts.models import User
from .models import (
    ChatRoom,
    Message,
    BlockedUser,
    MatchingQueue,
    OpenChatRoom,
    OpenChatParticipant,
    OpenChatMessage,
)
from .serializers import (
    ChatRoomSerializer,
    MessageSerializer,
    MessageCreateSerializer,
    MatchingRequestSerializer,
    BlockedUserSerializer,
    BlockUserSerializer,
    OpenChatRoomSerializer,
    OpenChatRoomCreateSerializer,
    OpenChatParticipantSerializer,
    OpenChatMessageSerializer,
    OpenChatMessageCreateSerializer,
)
from .matcher import MatchingService


class StartMatchingAPIView(APIView):
    """매칭 시작 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser, IsNotBanned, CanMatchToday]

    def post(self, request):
        serializer = MatchingRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        country_preference = serializer.validated_data.get("country_preference")
        gender_preference = serializer.validated_data.get("gender_preference")

        # 매칭 처리
        success, room, message = MatchingService.process_matching(
            request.user, country_preference, gender_preference
        )

        if success:
            return Response(
                {
                    "success": True,
                    "message": message,
                    "room": ChatRoomSerializer(room, context={"request": request}).data,
                },
                status=status.HTTP_201_CREATED,
            )

        return Response(
            {
                "success": False,
                "message": message,
            },
            status=status.HTTP_200_OK,
        )


class CancelMatchingAPIView(APIView):
    """매칭 취소 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def post(self, request):
        deleted_count = MatchingService.remove_from_queue(request.user)

        if deleted_count > 0:
            return Response(
                {"message": "매칭이 취소되었습니다."},
                status=status.HTTP_200_OK,
            )

        return Response(
            {"message": "매칭 대기 중이 아닙니다."},
            status=status.HTTP_400_BAD_REQUEST,
        )


class MatchingStatusAPIView(APIView):
    """매칭 상태 확인 API"""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        from django.utils import timezone
        from datetime import timedelta

        # 1. 먼저 최근 생성된 ChatRoom 확인 (5초 이내)
        recent_room = ChatRoom.objects.filter(
            Q(user1=request.user) | Q(user2=request.user),
            is_active=True,
            created_at__gte=timezone.now() - timedelta(seconds=5)
        ).order_by('-created_at').first()

        if recent_room:
            return Response(
                {
                    "is_matching": False,
                    "matched_room": recent_room.id,
                },
                status=status.HTTP_200_OK,
            )

        # 2. MatchingQueue 확인
        try:
            queue = MatchingQueue.objects.get(user=request.user)
            position = MatchingService.get_queue_position(request.user)

            return Response(
                {
                    "is_matching": True,
                    "position": position,
                    "country_preference": queue.country_preference,
                    "created_at": queue.created_at,
                },
                status=status.HTTP_200_OK,
            )
        except MatchingQueue.DoesNotExist:
            return Response(
                {"is_matching": False},
                status=status.HTTP_200_OK,
            )


class ChatRoomListAPIView(generics.ListAPIView):
    """내 채팅방 목록 조회 API"""

    serializer_class = ChatRoomSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        user = self.request.user

        # 본인이 참여한 채팅방
        return ChatRoom.objects.filter(
            Q(user1=user) | Q(user2=user),
            is_active=True,
        ).select_related("user1", "user2").prefetch_related("messages")


class ChatRoomDetailAPIView(generics.RetrieveAPIView):
    """채팅방 상세 조회 API"""

    serializer_class = ChatRoomSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        user = self.request.user
        return ChatRoom.objects.filter(Q(user1=user) | Q(user2=user))


class LeaveChatRoomAPIView(APIView):
    """채팅방 나가기 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def post(self, request, room_id):
        room = get_object_or_404(
            ChatRoom,
            Q(id=room_id) & (Q(user1=request.user) | Q(user2=request.user)),
        )

        # 사용자가 나감 처리
        room.mark_user_left(request.user)

        return Response(
            {"message": "채팅방을 나갔습니다."},
            status=status.HTTP_200_OK,
        )


class MessageListAPIView(generics.ListAPIView):
    """채팅방 메시지 목록 조회 API"""

    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        room_id = self.kwargs.get("room_id")
        user = self.request.user

        # 본인이 참여한 채팅방인지 확인
        room = get_object_or_404(
            ChatRoom,
            Q(id=room_id) & (Q(user1=user) | Q(user2=user)),
        )

        # 메시지 조회
        return Message.objects.filter(room=room).select_related("sender")


class MessageCreateAPIView(generics.CreateAPIView):
    """메시지 전송 API"""

    serializer_class = MessageCreateSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser, IsNotBanned]

    def perform_create(self, serializer):
        room_id = self.kwargs.get("room_id")
        user = self.request.user

        # 본인이 참여한 채팅방인지 확인
        room = get_object_or_404(
            ChatRoom,
            Q(id=room_id) & (Q(user1=user) | Q(user2=user)),
            is_active=True,
        )

        # 본인이 나간 채팅방인지 확인
        if (room.user1 == user and room.user1_left) or (
            room.user2 == user and room.user2_left
        ):
            raise serializers.ValidationError("이미 나간 채팅방입니다.")

        # 메시지 생성
        serializer.save(room=room, sender=user)


class MarkMessagesAsReadAPIView(APIView):
    """메시지 읽음 처리 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def post(self, request, room_id):
        user = request.user

        # 본인이 참여한 채팅방인지 확인
        room = get_object_or_404(
            ChatRoom,
            Q(id=room_id) & (Q(user1=user) | Q(user2=user)),
        )

        # 상대방이 보낸 읽지 않은 메시지를 모두 읽음 처리
        unread_messages = Message.objects.filter(
            room=room, is_read=False
        ).exclude(sender=user)

        count = unread_messages.update(is_read=True)

        return Response(
            {"message": f"{count}개의 메시지를 읽었습니다."},
            status=status.HTTP_200_OK,
        )


class BlockUserAPIView(APIView):
    """사용자 차단 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def post(self, request):
        serializer = BlockUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user_id = serializer.validated_data["user_id"]
        reason = serializer.validated_data.get("reason", "")

        # 차단할 사용자 확인
        blocked_user = get_object_or_404(User, id=user_id)

        if blocked_user == request.user:
            return Response(
                {"error": "자신을 차단할 수 없습니다."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 이미 차단했는지 확인
        if BlockedUser.objects.filter(
            user=request.user, blocked_user=blocked_user
        ).exists():
            return Response(
                {"error": "이미 차단한 사용자입니다."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 차단 처리
        BlockedUser.objects.create(
            user=request.user, blocked_user=blocked_user, reason=reason
        )

        # 해당 사용자와의 활성 채팅방 비활성화
        ChatRoom.objects.filter(
            Q(user1=request.user, user2=blocked_user)
            | Q(user1=blocked_user, user2=request.user),
            is_active=True,
        ).update(is_active=False)

        return Response(
            {"message": "사용자를 차단했습니다."},
            status=status.HTTP_201_CREATED,
        )


class UnblockUserAPIView(APIView):
    """사용자 차단 해제 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def post(self, request, user_id):
        blocked_user = get_object_or_404(User, id=user_id)

        # 차단 해제
        deleted_count = BlockedUser.objects.filter(
            user=request.user, blocked_user=blocked_user
        ).delete()[0]

        if deleted_count > 0:
            return Response(
                {"message": "차단을 해제했습니다."},
                status=status.HTTP_200_OK,
            )

        return Response(
            {"error": "차단하지 않은 사용자입니다."},
            status=status.HTTP_400_BAD_REQUEST,
        )


class BlockedUserListAPIView(generics.ListAPIView):
    """차단한 사용자 목록 조회 API"""

    serializer_class = BlockedUserSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        return BlockedUser.objects.filter(user=self.request.user).select_related(
            "blocked_user"
        )


# ============================================================================
# 오픈 채팅 API Views
# ============================================================================


class OpenChatRoomListCreateAPIView(generics.ListCreateAPIView):
    """오픈 채팅방 목록 조회 및 생성 API"""

    serializer_class = OpenChatRoomSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser, IsNotBanned]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return OpenChatRoomCreateSerializer
        return OpenChatRoomSerializer

    def get_queryset(self):
        from django.db.models import Case, When, Value, IntegerField

        queryset = OpenChatRoom.objects.filter(is_active=True).select_related("creator")

        # 필터링: 국가
        country = self.request.query_params.get("country")
        if country:
            queryset = queryset.filter(country_code=country)

        # 필터링: 카테고리 (카테고리 선택 시 USER_CREATED 방만 필터링, DEFAULT 방 제외)
        category = self.request.query_params.get("category")
        if category:
            # 카테고리가 선택되면 USER_CREATED 방만 해당 카테고리로 필터링
            queryset = queryset.filter(
                room_type=OpenChatRoom.RoomType.USER_CREATED,
                category=category
            )

        # 필터링: 방 타입
        room_type = self.request.query_params.get("type")
        if room_type:
            queryset = queryset.filter(room_type=room_type)

        # 검색: 제목
        search = self.request.query_params.get("search")
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search)
                | Q(description__icontains=search)
                | Q(tags__icontains=search)
            )

        # 필터링: 사용자 기준 필터
        user_filter = self.request.query_params.get("user_filter")
        if user_filter == "joined":
            # 내가 참여한 채팅방만
            queryset = queryset.filter(
                participants__user=self.request.user
            ).distinct()
        elif user_filter == "created":
            # 내가 만든 채팅방만
            queryset = queryset.filter(creator=self.request.user)

        # 정렬
        ordering = self.request.query_params.get("ordering", "recent")

        if ordering == "popular":
            # 추천: USER_CREATED만, 참여자 많은 순
            queryset = queryset.filter(
                room_type=OpenChatRoom.RoomType.USER_CREATED
            ).order_by('-participant_count', '-created_at')
        else:
            # 기본: USER_CREATED 방을 최상단에(최신순), 그 다음 DEFAULT 방을 최신순으로
            queryset = queryset.order_by(
                Case(
                    When(room_type='user_created', then=Value(0)),
                    When(room_type='default', then=Value(1)),
                    output_field=IntegerField(),
                ),
                '-created_at'
            )

        return queryset

    def perform_create(self, serializer):
        user = self.request.user

        # 일반 사용자(USER)는 USER_CREATED 방을 1개만 생성 가능
        if user.role == User.Role.USER:
            existing_room_count = OpenChatRoom.objects.filter(
                creator=user,
                room_type=OpenChatRoom.RoomType.USER_CREATED,
                is_active=True
            ).count()

            if existing_room_count > 0:
                raise serializers.ValidationError({
                    "detail": "이미 오픈 채팅방을 생성하셨습니다. 일반 사용자는 1개만 생성할 수 있습니다."
                })

        # 사용자 생성 채팅방으로 저장
        room = serializer.save(
            creator=user, room_type=OpenChatRoom.RoomType.USER_CREATED
        )

        # 생성자를 자동으로 참여자로 추가
        OpenChatParticipant.objects.create(room=room, user=user)

        # 참여자 수 증가
        room.increment_participant_count()

        # 입장 메시지 생성
        OpenChatMessage.objects.create(
            room=room,
            sender=None,
            message_type=OpenChatMessage.MessageType.JOIN,
            content=f"{user.nickname}님이 채팅방을 개설했습니다.",
        )


class OpenChatRoomDetailAPIView(generics.RetrieveAPIView):
    """오픈 채팅방 상세 조회 API"""

    serializer_class = OpenChatRoomSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        return OpenChatRoom.objects.filter(is_active=True).select_related("creator")


class OpenChatRoomDeleteAPIView(APIView):
    """오픈 채팅방 삭제 API (생성자, prime, owner 가능)"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def delete(self, request, pk):
        user = request.user
        room = get_object_or_404(OpenChatRoom, pk=pk)

        # 권한 확인
        is_creator = room.creator == user and room.room_type == OpenChatRoom.RoomType.USER_CREATED
        is_admin = user.role in [User.Role.PRIME, User.Role.OWNER]

        if not (is_creator or is_admin):
            return Response(
                {"error": "채팅방을 삭제할 권한이 없습니다."},
                status=status.HTTP_403_FORBIDDEN,
            )

        # 일반 사용자는 DEFAULT 방 삭제 불가
        if room.room_type == OpenChatRoom.RoomType.DEFAULT and not is_admin:
            return Response(
                {"error": "기본 채팅방은 삭제할 수 없습니다."},
                status=status.HTTP_403_FORBIDDEN,
            )

        # 비활성화 처리
        room.is_active = False
        room.save(update_fields=["is_active"])

        return Response(
            {"message": "채팅방이 삭제되었습니다."}, status=status.HTTP_200_OK
        )


class OpenChatRoomJoinAPIView(APIView):
    """오픈 채팅방 입장 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser, IsNotBanned]

    def post(self, request, pk):
        user = request.user

        # 채팅방 확인
        room = get_object_or_404(OpenChatRoom, pk=pk, is_active=True)

        # 비공개 방 비밀번호 확인
        if not room.is_public:
            password = request.data.get("password", "")
            if not password or password != room.password:
                return Response(
                    {"error": "비밀번호가 올바르지 않습니다."},
                    status=status.HTTP_403_FORBIDDEN,
                )

        # 이미 참여 중인지 확인
        if OpenChatParticipant.objects.filter(room=room, user=user).exists():
            return Response(
                {"message": "이미 참여 중인 채팅방입니다."},
                status=status.HTTP_200_OK,
            )

        # 정원 확인
        if room.is_full():
            return Response(
                {"error": "채팅방이 가득 찼습니다."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 참여자 추가
        participant = OpenChatParticipant.objects.create(room=room, user=user)

        # 참여자 수 증가
        room.increment_participant_count()

        # 입장 메시지 생성
        OpenChatMessage.objects.create(
            room=room,
            sender=None,
            message_type=OpenChatMessage.MessageType.JOIN,
            content=f"{user.nickname}님이 입장했습니다.",
        )

        return Response(
            {
                "message": "채팅방에 입장했습니다.",
                "room": OpenChatRoomSerializer(room, context={"request": request}).data,
            },
            status=status.HTTP_201_CREATED,
        )


class OpenChatRoomLeaveAPIView(APIView):
    """오픈 채팅방 퇴장 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def post(self, request, pk):
        user = request.user

        # 채팅방 확인
        room = get_object_or_404(OpenChatRoom, pk=pk)

        # 참여자 확인
        try:
            participant = OpenChatParticipant.objects.get(room=room, user=user)
        except OpenChatParticipant.DoesNotExist:
            return Response(
                {"error": "참여하지 않은 채팅방입니다."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 방장 여부 확인
        is_creator = (room.creator == user)
        is_user_created_room = (room.room_type == OpenChatRoom.RoomType.USER_CREATED)

        # 참여자 삭제
        participant.delete()

        # 참여자 수 감소
        room.decrement_participant_count()

        # 퇴장 메시지 생성
        OpenChatMessage.objects.create(
            room=room,
            sender=None,
            message_type=OpenChatMessage.MessageType.LEAVE,
            content=f"{user.nickname}님이 퇴장했습니다.",
        )

        # 남은 참여자 수 확인
        remaining_participants = OpenChatParticipant.objects.filter(room=room).count()

        if remaining_participants == 0:
            # 마지막 참여자가 나감
            if is_user_created_room:
                # USER_CREATED 방만 자동 삭제
                room.is_active = False
                room.save(update_fields=["is_active", "updated_at"])
                return Response(
                    {"message": "마지막 참여자가 나가 채팅방이 삭제되었습니다."},
                    status=status.HTTP_200_OK
                )
            else:
                # DEFAULT 방은 유지
                return Response(
                    {"message": "채팅방에서 퇴장했습니다."},
                    status=status.HTTP_200_OK
                )

        elif is_creator and is_user_created_room:
            # USER_CREATED 방의 방장이 나갔지만 참여자가 남음 → 방장 승계
            next_owner_participant = room.get_next_owner()

            if next_owner_participant:
                old_owner = room.transfer_ownership(next_owner_participant.user)

                # 방장 변경 시스템 메시지
                OpenChatMessage.objects.create(
                    room=room,
                    sender=None,
                    message_type=OpenChatMessage.MessageType.SYSTEM,
                    content=f"{next_owner_participant.user.nickname}님이 새로운 방장이 되었습니다.",
                )

        return Response(
            {"message": "채팅방에서 퇴장했습니다."}, status=status.HTTP_200_OK
        )


class OpenChatRoomParticipantsAPIView(generics.ListAPIView):
    """오픈 채팅방 참여자 목록 API"""

    serializer_class = OpenChatParticipantSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        room_id = self.kwargs.get("pk")
        room = get_object_or_404(OpenChatRoom, pk=room_id, is_active=True)

        return OpenChatParticipant.objects.filter(room=room).select_related("user")


class OpenChatMessageListAPIView(generics.ListAPIView):
    """오픈 채팅방 메시지 목록 조회 API"""

    serializer_class = OpenChatMessageSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        room_id = self.kwargs.get("room_id")

        # 채팅방 확인
        room = get_object_or_404(OpenChatRoom, pk=room_id, is_active=True)

        # 참여자 확인
        is_participant = OpenChatParticipant.objects.filter(
            room=room, user=self.request.user
        ).exists()

        if not is_participant:
            # 참여하지 않은 경우 빈 쿼리셋 반환
            return OpenChatMessage.objects.none()

        # 메시지 조회
        return OpenChatMessage.objects.filter(room=room).select_related("sender")


class OpenChatMessageCreateAPIView(generics.CreateAPIView):
    """오픈 채팅 메시지 전송 API"""

    serializer_class = OpenChatMessageCreateSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser, IsNotBanned]

    def perform_create(self, serializer):
        room_id = self.kwargs.get("room_id")
        user = self.request.user

        # 채팅방 확인
        room = get_object_or_404(OpenChatRoom, pk=room_id, is_active=True)

        # 참여자 확인
        try:
            participant = OpenChatParticipant.objects.get(room=room, user=user)
        except OpenChatParticipant.DoesNotExist:
            raise serializers.ValidationError("참여하지 않은 채팅방입니다.")

        # 메시지 생성
        serializer.save(
            room=room, sender=user, message_type=OpenChatMessage.MessageType.TEXT
        )

        # 마지막 읽은 시간 업데이트
        participant.update_last_read()

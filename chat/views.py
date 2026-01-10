from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from django.shortcuts import get_object_or_404, render
from django.contrib.auth import get_user_model
from django.contrib.auth.decorators import login_required
from django.utils import timezone
from django.utils.translation import gettext as _
from django.utils.decorators import method_decorator
from django_ratelimit.decorators import ratelimit
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

from .models import (
    Conversation, Message, ConversationParticipant, AnonymousMatchingPreference, Report,
    OpenChatRoom, OpenChatParticipant, OpenChatMessage, OpenChatFavorite, OpenChatKick,
    ConnectionRequest
)
from .serializers import (
    ConversationListSerializer,
    ConversationDetailSerializer,
    MessageSerializer,
    AnonymousMatchingPreferenceSerializer,
    ReportSerializer,
    OpenChatRoomListSerializer,
    OpenChatRoomDetailSerializer,
    OpenChatRoomCreateSerializer,
    OpenChatMessageSerializer,
    OpenChatFavoriteSerializer,
    OpenChatKickSerializer
)
from .matcher import matching_queue, create_anonymous_conversation
from accounts.models import Follow

User = get_user_model()


# Template views for messages pages
@login_required
def messages_list_view(request):
    """메시지 리스트 페이지 렌더링"""
    return render(request, 'messages.html')


@login_required
def conversation_detail_view(request, conversation_id):
    """특정 대화 페이지 렌더링"""
    # 대화 존재 여부 및 참가자 확인
    conversation = get_object_or_404(
        Conversation.objects.filter(participants=request.user),
        id=conversation_id
    )

    # 읽지 않은 메시지를 읽음 상태로 표시
    Message.objects.filter(
        conversation=conversation,
        is_read=False
    ).exclude(sender=request.user).update(is_read=True)

    # 상대방 정보 가져오기
    other_user = conversation.get_other_user(request.user)

    # 차단 상태 확인
    is_blocking = request.user.is_blocking(other_user)
    is_blocked_by = other_user.is_blocking(request.user)

    return render(request, 'conversation.html', {
        'conversation_id': conversation_id,
        'other_user': other_user,
        'is_blocking': is_blocking,
        'is_blocked_by': is_blocked_by,
    })


# REST API ViewSets
@method_decorator(ratelimit(key='user', rate='20/h', method='POST', block=True), name='create')
class ConversationViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing conversations

    Rate Limit: 20 conversation creations per hour per user (prevent spam)
    """
    permission_classes = [IsAuthenticated]

    def get_serializer_context(self):
        """Ensure request is always in serializer context"""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_serializer_class(self):
        if self.action == 'list':
            return ConversationListSerializer
        return ConversationDetailSerializer

    def get_queryset(self):
        """현재 사용자가 참가한 일반 채팅만 반환 (익명 채팅 제외, is_active=True인 대화만)"""
        return Conversation.objects.filter(
            participant_relations__user=self.request.user,
            participant_relations__is_active=True,
            is_anonymous=False
        ).distinct().order_by('-updated_at')

    def retrieve(self, request, pk=None):
        """특정 대화의 상세 정보 및 메시지 내역 조회"""
        from accounts.models import Block

        conversation = get_object_or_404(
            Conversation.objects.filter(participants=request.user),
            pk=pk
        )

        # 차단한 사용자의 메시지는 읽음 처리 안함
        blocked_user_ids = Block.objects.filter(
            blocker=request.user,
            is_active=True  # 활성 차단만 필터링
        ).values_list('blocked_id', flat=True)

        unread_messages = Message.objects.filter(
            conversation=conversation,
            is_read=False
        ).exclude(sender=request.user)

        if blocked_user_ids:
            unread_messages = unread_messages.exclude(sender_id__in=blocked_user_ids)

        unread_messages.update(is_read=True)

        serializer = self.get_serializer(conversation)
        return Response(serializer.data)

    def create(self, request):
        """새 대화 생성 또는 기존 대화 반환"""
        other_user_id = request.data.get('user_id')
        if not other_user_id:
            return Response(
                {'error': 'user_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            other_user = User.objects.get(id=other_user_id)
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # 자기 자신과 대화 불가
        if other_user == request.user:
            return Response(
                {'error': 'Cannot create conversation with yourself'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 차단 관계 확인
        from accounts.models import Block
        is_blocked = Block.objects.filter(
            Q(blocker=request.user, blocked=other_user) |
            Q(blocker=other_user, blocked=request.user),
            is_active=True  # 활성 차단만 체크
        ).exists()

        if is_blocked:
            return Response(
                {'error': '차단된 사용자와는 대화를 시작할 수 없습니다'},
                status=status.HTTP_403_FORBIDDEN
            )

        # 기존 일반 대화 확인 (익명 채팅 제외)
        existing_conversation = Conversation.objects.filter(
            participants=request.user,
            is_anonymous=False
        ).filter(
            participants=other_user
        ).first()

        if existing_conversation:
            serializer = ConversationDetailSerializer(
                existing_conversation,
                context={'request': request}
            )
            return Response(serializer.data)

        # 새 일반 대화 생성
        conversation = Conversation.objects.create(is_anonymous=False)
        conversation.participants.add(request.user, other_user)

        serializer = ConversationDetailSerializer(
            conversation,
            context={'request': request}
        )
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def send_message(self, request, pk=None):
        """
        메시지 전송 (REST API 방식, WebSocket 대안)
        WebSocket을 사용할 수 없는 환경에서 사용
        """
        conversation = get_object_or_404(
            Conversation.objects.filter(participants=request.user),
            pk=pk
        )

        content = request.data.get('content', '').strip()
        if not content:
            return Response(
                {'error': 'Content is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 상대방이 나간 경우 자동 재입장 처리
        other_user = conversation.get_other_user(request.user)
        if other_user:
            other_participant = ConversationParticipant.objects.filter(
                conversation=conversation,
                user=other_user
            ).first()

            if other_participant and not other_participant.is_active:
                # 자동 재입장 (left_at은 유지하여 나간 시점 이후 메시지만 보이도록)
                other_participant.is_active = True
                # left_at은 None으로 설정하지 않음 - 나간 시점을 기억해야 함
                other_participant.save()

        message = Message.objects.create(
            conversation=conversation,
            sender=request.user,
            content=content
        )

        # 대화의 updated_at 자동 업데이트
        conversation.save()

        serializer = MessageSerializer(message)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def leave_conversation(request, pk):
    """
    대화방 나가기 API
    POST /api/chat/conversations/<id>/leave/
    """
    try:
        # 참가자 확인 (is_active 상태와 무관하게 먼저 찾기)
        participant = ConversationParticipant.objects.get(
            user=request.user,
            conversation_id=pk
        )
    except ConversationParticipant.DoesNotExist:
        return Response(
            {'error': '대화방을 찾을 수 없습니다'},
            status=status.HTTP_404_NOT_FOUND
        )

    # 나가기 처리 (idempotent: 이미 나간 상태여도 항상 성공)
    participant.is_active = False
    participant.left_at = timezone.now()
    participant.save()

    return Response(
        {'message': '대화방을 나갔습니다'},
        status=status.HTTP_200_OK
    )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_total_unread_count(request):
    """
    전체 읽지 않은 메시지 개수 조회 API
    GET /messages/api/unread-count/

    Returns:
        {"total_unread_count": 5}
    """
    total_unread = 0

    # 현재 사용자가 참가한 모든 대화 조회
    # is_active 필터 제거: 나갔다가 다시 들어온 대화방의 메시지도 카운트
    conversations = Conversation.objects.filter(
        participants=request.user
    ).distinct()

    # 각 대화의 읽지 않은 메시지 개수 합산
    for conversation in conversations:
        unread = conversation.get_unread_count(request.user)
        if unread > 0:
            print(f"[API] Conversation {conversation.id}: {unread} unread messages")
        total_unread += unread

    print(f"[API] Total unread count for user {request.user.id}: {total_unread}")

    return Response({
        'total_unread_count': total_unread
    })


# Anonymous Chat API Views

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def matching_preference_view(request):
    """
    매칭 선호도 조회/업데이트 API
    GET /api/chat/matching/preference/
    POST /api/chat/matching/preference/
    """
    # Get or create preference
    preference, created = AnonymousMatchingPreference.objects.get_or_create(
        user=request.user
    )

    if request.method == 'GET':
        serializer = AnonymousMatchingPreferenceSerializer(preference)
        return Response(serializer.data)

    elif request.method == 'POST':
        serializer = AnonymousMatchingPreferenceSerializer(
            preference,
            data=request.data,
            partial=True
        )
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def start_matching_view(request):
    """
    매칭 시작 API
    POST /api/chat/matching/start/

    Request body: {
        "preferred_gender": "any" | "male" | "female" | "other",
        "preferred_country": "" (blank for all) or country code,
        "chat_mode": "text" | "video"
    }

    Returns:
        - If match found: {"status": "matched", "conversation_id": 123}
        - If queued: {"status": "queued", "position": 5}
    """
    # Get or create preference
    preference, _ = AnonymousMatchingPreference.objects.get_or_create(
        user=request.user
    )

    # Update preference with request data
    preferred_gender = request.data.get('preferred_gender', 'any')
    preferred_country = request.data.get('preferred_country', '')
    chat_mode = request.data.get('chat_mode', 'text')

    preference.preferred_gender = preferred_gender
    preference.preferred_country = preferred_country
    preference.chat_mode = chat_mode
    preference.is_searching = True
    preference.save()

    # Try to find match
    preferences = {
        'preferred_gender': preferred_gender,
        'preferred_country': preferred_country,
        'chat_mode': chat_mode
    }

    matched_user_id = matching_queue.find_match(request.user.id, preferences)

    if matched_user_id:
        # Match found - create anonymous conversation
        conversation = create_anonymous_conversation(request.user.id, matched_user_id)

        # Notify the waiting user (matched_user_id) via WebSocket
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'matching_{matched_user_id}',  # User A's matching group
            {
                'type': 'match_found',
                'conversation_id': conversation.id,
                'anonymous_room_id': conversation.anonymous_room_id
            }
        )

        # Stop searching for both users
        preference.is_searching = False
        preference.save()

        # Also stop searching for the matched user
        try:
            matched_preference = AnonymousMatchingPreference.objects.get(user_id=matched_user_id)
            matched_preference.is_searching = False
            matched_preference.save()
        except AnonymousMatchingPreference.DoesNotExist:
            pass

        return Response({
            'status': 'matched',
            'conversation_id': conversation.id,
            'anonymous_room_id': conversation.anonymous_room_id
        })
    else:
        # No match - add to queue
        added = matching_queue.add_to_queue(request.user.id, preferences)
        position = matching_queue.get_queue_position(request.user.id)

        return Response({
            'status': 'queued',
            'position': position,
            'queue_size': matching_queue.get_queue_size()
        })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def stop_matching_view(request):
    """
    매칭 중지 API
    POST /api/chat/matching/stop/
    """
    # Remove from queue
    removed = matching_queue.remove_from_queue(request.user.id)

    # Update preference
    try:
        preference = AnonymousMatchingPreference.objects.get(user=request.user)
        preference.is_searching = False
        preference.save()
    except AnonymousMatchingPreference.DoesNotExist:
        pass

    return Response({
        'status': 'stopped',
        'removed_from_queue': removed
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def connection_request_view(request):
    """
    연결 요청 전송 API
    POST /api/anonymous/connection-request/

    Request body: {
        "conversation_id": 123
    }
    """
    conversation_id = request.data.get('conversation_id')

    if not conversation_id:
        return Response(
            {'error': '대화방 ID가 필요합니다'},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        conversation = Conversation.objects.get(id=conversation_id, is_anonymous=True)
    except Conversation.DoesNotExist:
        return Response(
            {'error': '대화방을 찾을 수 없습니다'},
            status=status.HTTP_404_NOT_FOUND
        )

    # Get other user in conversation
    participants = conversation.participants.exclude(id=request.user.id)
    if not participants.exists():
        return Response(
            {'error': '대화 상대를 찾을 수 없습니다'},
            status=status.HTTP_404_NOT_FOUND
        )

    other_user = participants.first()

    # Check if request already exists
    existing_request = ConnectionRequest.objects.filter(
        conversation=conversation,
        requester=request.user,
        receiver=other_user,
        status='pending'
    ).first()

    if existing_request:
        return Response(
            {'error': '이미 연결 요청을 보냈습니다'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Create connection request
    connection_request = ConnectionRequest.objects.create(
        conversation=conversation,
        requester=request.user,
        receiver=other_user
    )

    # Send WebSocket notification to receiver
    channel_layer = get_channel_layer()
    room_group_name = f'anonymous_chat_{conversation.id}'

    async_to_sync(channel_layer.group_send)(
        room_group_name,
        {
            'type': 'connection_request',
            'request_id': connection_request.id,
            'requester_id': request.user.id
        }
    )

    return Response({
        'status': 'sent',
        'message': '연결 요청을 보냈습니다',
        'request_id': connection_request.id
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def connection_respond_view(request):
    """
    연결 요청 응답 API
    POST /api/anonymous/connection-respond/

    Request body: {
        "request_id": 123,
        "accept": true/false
    }
    """
    request_id = request.data.get('request_id')
    accept = request.data.get('accept', False)

    if not request_id:
        return Response(
            {'error': '요청 ID가 필요합니다'},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        connection_request = ConnectionRequest.objects.get(
            id=request_id,
            receiver=request.user,
            status='pending'
        )
    except ConnectionRequest.DoesNotExist:
        return Response(
            {'error': '연결 요청을 찾을 수 없습니다'},
            status=status.HTTP_404_NOT_FOUND
        )

    channel_layer = get_channel_layer()
    room_group_name = f'anonymous_chat_{connection_request.conversation.id}'

    if accept:
        # Accept request - create follow relationship
        connection_request.status = 'accepted'
        connection_request.save()

        # Create follow relationship
        Follow.objects.get_or_create(
            follower=connection_request.requester,
            following=connection_request.receiver
        )

        # Send acceptance notification
        async_to_sync(channel_layer.group_send)(
            room_group_name,
            {
                'type': 'connection_accepted',
                'request_id': connection_request.id,
                'requester_id': connection_request.requester.id,
                'receiver_id': connection_request.receiver.id
            }
        )

        return Response({
            'status': 'accepted',
            'message': '연결 요청을 수락했습니다'
        })
    else:
        # Reject request
        connection_request.status = 'rejected'
        connection_request.save()

        # Send rejection notification
        async_to_sync(channel_layer.group_send)(
            room_group_name,
            {
                'type': 'connection_rejected',
                'request_id': connection_request.id,
                'requester_id': connection_request.requester.id
            }
        )

        return Response({
            'status': 'rejected',
            'message': '연결 요청을 거절했습니다'
        })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@ratelimit(key='user', rate='5/h', method='POST', block=True)
def report_user_view(request):
    """
    사용자 신고 API with Evidence Capture
    POST /api/chat/report/

    Request body (multipart/form-data): {
        "reported_user": 123,
        "conversation": 456 (optional),
        "report_type": "abuse" | "spam" | "inappropriate" | "harassment" | "other",
        "description": "설명",
        "video_frame": <file> (optional - for video chat reports)
    }

    Rate Limit: 5 chat reports per hour per user (prevent abuse)
    """
    from .models import ConversationBuffer

    serializer = ReportSerializer(
        data=request.data,
        context={'request': request}
    )

    if serializer.is_valid():
        # Create report
        report = serializer.save(reporter=request.user)

        # Attach message buffer snapshot (text evidence)
        conversation_id = request.data.get('conversation')
        if conversation_id:
            try:
                conversation = Conversation.objects.get(id=conversation_id)

                # Get message buffer snapshot
                try:
                    buffer = ConversationBuffer.objects.get(conversation=conversation)
                    report.message_snapshot = buffer.get_snapshot()
                except ConversationBuffer.DoesNotExist:
                    # No buffer exists yet, that's okay
                    pass

            except Conversation.DoesNotExist:
                pass

        # Attach video frame if provided (video chat evidence)
        video_frame = request.FILES.get('video_frame')
        if video_frame:
            report.video_frame = video_frame

        # Save report with evidence
        report.save()

        return Response(serializer.data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def follow_from_anonymous_view(request):
    """
    익명 채팅에서 대화 상대와 연결(팔로우) API
    POST /api/chat/anonymous/follow/

    Request body: {
        "conversation_id": 123
    }
    """
    from accounts.models import Follow

    conversation_id = request.data.get('conversation_id')
    if not conversation_id:
        return Response(
            {'error': 'conversation_id is required'},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        # Get anonymous conversation
        conversation = Conversation.objects.get(
            id=conversation_id,
            is_anonymous=True,
            participants=request.user
        )
    except Conversation.DoesNotExist:
        return Response(
            {'error': '대화방을 찾을 수 없습니다'},
            status=status.HTTP_404_NOT_FOUND
        )

    # Get other user
    other_user = conversation.get_other_user(request.user)
    if not other_user:
        return Response(
            {'error': '대화 상대를 찾을 수 없습니다'},
            status=status.HTTP_404_NOT_FOUND
        )

    # Create follow relationship
    follow, created = Follow.objects.get_or_create(
        follower=request.user,
        following=other_user
    )

    if created:
        return Response({
            'message': '팔로우되었습니다',
            'user_id': other_user.id,
            'nickname': other_user.nickname
        }, status=status.HTTP_201_CREATED)
    else:
        return Response({
            'message': '이미 팔로우 중입니다',
            'user_id': other_user.id,
            'nickname': other_user.nickname
        })


# Open Chat Room Views
@login_required
def open_chat_list_view(request):
    """오픈 채팅방 리스트 페이지 렌더링"""
    return render(request, 'learning/chat.html')


@login_required
def open_chat_room_view(request, room_id):
    """오픈 채팅방 상세 페이지 렌더링"""
    room = get_object_or_404(OpenChatRoom, id=room_id, is_active=True)
    is_user_admin = room.is_admin(request.user)
    return render(request, 'learning/chat_room.html', {
        'room_id': room_id,
        'room': room,
        'is_user_admin': is_user_admin
    })


@method_decorator(ratelimit(key='user', rate='10/h', method='POST', block=True), name='create')
class OpenChatRoomViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing open chat rooms

    list: Get all active rooms
    retrieve: Get room details with messages
    create: Create a new room
    join: Join a room
    leave: Leave a room

    Rate Limit: 10 room creations per hour per user (prevent spam)
    """
    permission_classes = [IsAuthenticated]

    def get_serializer_context(self):
        """Ensure request is always in serializer context"""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_serializer_class(self):
        """Return appropriate serializer based on action"""
        if self.action == 'create':
            return OpenChatRoomCreateSerializer
        elif self.action == 'list':
            return OpenChatRoomListSerializer
        return OpenChatRoomDetailSerializer

    def get_queryset(self):
        """Return all active rooms, optionally filtered"""
        queryset = OpenChatRoom.objects.filter(is_active=True)

        # Filter by country
        country_code = self.request.query_params.get('country_code')
        if country_code:
            queryset = queryset.filter(country_code=country_code)

        # Filter by category
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)

        # Search by name
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(name__icontains=search)

        return queryset.order_by('-last_activity')

    def create(self, request):
        """Create a new open chat room"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        room = serializer.save()

        # Return detail view of created room
        detail_serializer = OpenChatRoomDetailSerializer(
            room,
            context=self.get_serializer_context()
        )
        return Response(
            detail_serializer.data,
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['post'])
    def join(self, request, pk=None):
        """Join an open chat room"""
        room = self.get_object()

        # Check password for private rooms
        if not room.is_public:
            provided_password = request.data.get('password', '')
            if not provided_password or provided_password != room.password:
                return Response(
                    {'error': '비밀번호가 일치하지 않습니다'},
                    status=status.HTTP_403_FORBIDDEN
                )

        # Check if already a participant
        if room.is_participant(request.user):
            return Response(
                {'message': '이미 참가 중인 채팅방입니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if room is full
        if not room.can_join(request.user):
            return Response(
                {'error': '채팅방이 가득 찼습니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if user left before and rejoin
        try:
            participant = OpenChatParticipant.objects.get(
                user=request.user,
                room=room
            )
            participant.is_active = True
            participant.left_at = None
            participant.save()
        except OpenChatParticipant.DoesNotExist:
            # Create new participant
            participant = OpenChatParticipant.objects.create(
                user=request.user,
                room=room,
                is_active=True
            )

        # Update room last activity
        room.last_activity = timezone.now()
        room.save()

        return Response({
            'message': '채팅방에 참가했습니다',
            'room_id': room.id,
            'room_name': room.name
        })

    @action(detail=True, methods=['post'])
    def leave(self, request, pk=None):
        """Leave an open chat room"""
        room = self.get_object()

        # Check if participant
        if not room.is_participant(request.user):
            return Response(
                {'error': '참가하지 않은 채팅방입니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get participant
        try:
            participant = OpenChatParticipant.objects.get(
                user=request.user,
                room=room,
                is_active=True
            )
        except OpenChatParticipant.DoesNotExist:
            return Response(
                {'error': '참가 정보를 찾을 수 없습니다'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Check if creator leaving (and if room should be deleted)
        if room.creator == request.user and room.should_delete_on_creator_leave():
            # Check for confirmation
            confirmed = request.data.get('confirmed', False)

            if not confirmed:
                # Require confirmation
                return Response({
                    'requires_confirmation': True,
                    'message': _('방장이 나가면 채팅방이 삭제됩니다. 계속하시겠습니까?')
                }, status=status.HTTP_200_OK)

            # Confirmed - deactivate room and notify participants
            room.deactivate_room()

            # Also mark creator as left
            participant.is_active = False
            participant.left_at = timezone.now()
            participant.save()

            return Response({
                'message': _('방이 삭제되었습니다'),
                'room_deleted': True
            })

        # Regular participant leaving
        participant.is_active = False
        participant.left_at = timezone.now()
        participant.save()

        return Response({
            'message': _('채팅방에서 나갔습니다')
        })

    @action(detail=True, methods=['post'])
    def favorite(self, request, pk=None):
        """Add room to favorites"""
        room = self.get_object()

        # Check if already favorited
        if OpenChatFavorite.objects.filter(user=request.user, room=room).exists():
            return Response(
                {'message': '이미 즐겨찾기에 추가된 채팅방입니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create favorite
        favorite = OpenChatFavorite.objects.create(
            user=request.user,
            room=room
        )

        serializer = OpenChatFavoriteSerializer(favorite)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def unfavorite(self, request, pk=None):
        """Remove room from favorites"""
        room = self.get_object()

        try:
            favorite = OpenChatFavorite.objects.get(user=request.user, room=room)
            favorite.delete()
            return Response({'message': '즐겨찾기에서 제거되었습니다'})
        except OpenChatFavorite.DoesNotExist:
            return Response(
                {'error': '즐겨찾기에 없는 채팅방입니다'},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=True, methods=['post'])
    def grant_admin(self, request, pk=None):
        """Grant admin privileges to a user"""
        room = self.get_object()

        # Check if requester is admin
        if not room.is_admin(request.user):
            return Response(
                {'error': '관리자 권한이 필요합니다'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get target user ID
        target_user_id = request.data.get('user_id')
        if not target_user_id:
            return Response(
                {'error': 'user_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            target_user = User.objects.get(id=target_user_id)
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Check if target user is a participant
        try:
            participant = OpenChatParticipant.objects.get(
                user=target_user,
                room=room,
                is_active=True
            )
        except OpenChatParticipant.DoesNotExist:
            return Response(
                {'error': '채팅방 참가자가 아닙니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if already admin
        if participant.is_admin:
            return Response(
                {'message': '이미 관리자입니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Grant admin
        participant.is_admin = True
        participant.admin_granted_at = timezone.now()
        participant.save()

        return Response({
            'message': f'{target_user.nickname}님에게 관리자 권한이 부여되었습니다',
            'user_id': target_user.id,
            'nickname': target_user.nickname
        })

    @action(detail=True, methods=['post'])
    def revoke_admin(self, request, pk=None):
        """Revoke admin privileges from a user"""
        room = self.get_object()

        # Check if requester is admin
        if not room.is_admin(request.user):
            return Response(
                {'error': '관리자 권한이 필요합니다'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get target user ID
        target_user_id = request.data.get('user_id')
        if not target_user_id:
            return Response(
                {'error': 'user_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            target_user = User.objects.get(id=target_user_id)
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Prevent revoking creator's admin
        if room.creator == target_user:
            return Response(
                {'error': '방장의 관리자 권한은 해제할 수 없습니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if target user is a participant
        try:
            participant = OpenChatParticipant.objects.get(
                user=target_user,
                room=room,
                is_active=True
            )
        except OpenChatParticipant.DoesNotExist:
            return Response(
                {'error': '채팅방 참가자가 아닙니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if not admin
        if not participant.is_admin:
            return Response(
                {'message': '관리자가 아닙니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Revoke admin
        participant.is_admin = False
        participant.save()

        return Response({
            'message': f'{target_user.nickname}님의 관리자 권한이 해제되었습니다',
            'user_id': target_user.id,
            'nickname': target_user.nickname
        })

    @action(detail=True, methods=['post'])
    def kick_user(self, request, pk=None):
        """Kick a user from the room"""
        room = self.get_object()

        # Check if requester is admin
        if not room.is_admin(request.user):
            return Response(
                {'error': '관리자 권한이 필요합니다'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get target user ID
        kicked_user_id = request.data.get('user_id')
        if not kicked_user_id:
            return Response(
                {'error': 'user_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            kicked_user = User.objects.get(id=kicked_user_id)
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Prevent kicking creator
        if room.creator == kicked_user:
            return Response(
                {'error': '방장은 강퇴할 수 없습니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Prevent kicking yourself
        if kicked_user == request.user:
            return Response(
                {'error': '자기 자신을 강퇴할 수 없습니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if target user is a participant
        try:
            participant = OpenChatParticipant.objects.get(
                user=kicked_user,
                room=room,
                is_active=True
            )
        except OpenChatParticipant.DoesNotExist:
            return Response(
                {'error': '채팅방 참가자가 아닙니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get kick data
        reason = request.data.get('reason', '')
        ban_until = request.data.get('ban_until')  # Optional: datetime or None for permanent

        # Remove user from room
        participant.is_active = False
        participant.left_at = timezone.now()
        participant.save()

        # Create kick record
        kick_data = {
            'room': room.id,
            'kicked_user': kicked_user.id,
            'reason': reason
        }
        if ban_until:
            kick_data['ban_until'] = ban_until

        serializer = OpenChatKickSerializer(
            data=kick_data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        kick = serializer.save()

        # Broadcast kick event to WebSocket
        channel_layer = get_channel_layer()
        room_group_name = f'open_chat_{room.id}'
        async_to_sync(channel_layer.group_send)(
            room_group_name,
            {
                'type': 'user_kicked',
                'kicked_user_id': kicked_user.id,
                'kicked_user_nickname': kicked_user.nickname,
                'kicked_by_nickname': request.user.nickname,
                'reason': reason
            }
        )

        return Response({
            'message': f'{kicked_user.nickname}님이 강퇴되었습니다',
            'kick_id': kick.id,
            'kicked_user_id': kicked_user.id,
            'kicked_user_nickname': kicked_user.nickname,
            'is_permanent_ban': ban_until is None
        }, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def unban_user(self, request, pk=None):
        """Unban a kicked user"""
        room = self.get_object()

        # Check if requester is admin
        if not room.is_admin(request.user):
            return Response(
                {'error': '관리자 권한이 필요합니다'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get target user ID
        user_id = request.data.get('user_id')
        if not user_id:
            return Response(
                {'error': 'user_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Find latest kick record
        latest_kick = OpenChatKick.objects.filter(
            room=room,
            kicked_user=user
        ).order_by('-kicked_at').first()

        if not latest_kick or not latest_kick.is_ban_active():
            return Response(
                {'error': '강퇴된 사용자가 아닙니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Unban by setting ban_until to past
        latest_kick.ban_until = timezone.now()
        latest_kick.save()

        return Response({
            'message': f'{user.nickname}님의 강퇴가 해제되었습니다',
            'user_id': user.id,
            'nickname': user.nickname
        })

    @action(detail=True, methods=['get'])
    def get_kicked_users(self, request, pk=None):
        """Get list of kicked users for this room"""
        room = self.get_object()

        # Check if requester is admin
        if not room.is_admin(request.user):
            return Response(
                {'error': '관리자 권한이 필요합니다'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get all kick records for this room, ordered by most recent
        kick_records = OpenChatKick.objects.filter(room=room).select_related('kicked_user').order_by('-kicked_at')

        # Build response data
        kicked_users = []
        for kick in kick_records:
            is_active = kick.is_ban_active()
            kicked_users.append({
                'kick_id': kick.id,
                'user_id': kick.kicked_user.id,
                'nickname': kick.kicked_user.nickname,
                'profile_picture': kick.kicked_user.profile_picture.url if kick.kicked_user.profile_picture else None,
                'kicked_by_nickname': kick.kicked_by.nickname,
                'kicked_at': kick.kicked_at,
                'ban_until': kick.ban_until,
                'is_permanent': kick.ban_until is None,
                'is_ban_active': is_active,
                'reason': kick.reason
            })

        return Response({
            'kicked_users': kicked_users,
            'total': len(kicked_users)
        })

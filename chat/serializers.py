import logging
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    Conversation, Message, ConversationParticipant, AnonymousMatchingPreference, Report,
    OpenChatRoom, OpenChatParticipant, OpenChatMessage, OpenChatFavorite, OpenChatKick
)

User = get_user_model()
logger = logging.getLogger(__name__)


class MessageSerializer(serializers.ModelSerializer):
    """Serializer for individual messages"""
    sender_nickname = serializers.CharField(source='sender.nickname', read_only=True)
    sender_profile_picture = serializers.CharField(source='sender.profile_picture', read_only=True)

    class Meta:
        model = Message
        fields = ('id', 'conversation', 'sender_id', 'sender_nickname', 'sender_profile_picture',
                  'content', 'created_at', 'is_read')
        read_only_fields = ('id', 'sender_id', 'sender_nickname', 'sender_profile_picture', 'created_at')


class ConversationListSerializer(serializers.ModelSerializer):
    """Serializer for conversation list (left panel)"""
    other_user = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = ('id', 'other_user', 'last_message', 'unread_count', 'updated_at')
        read_only_fields = ('id', 'other_user', 'last_message', 'unread_count', 'updated_at')

    def get_other_user(self, obj):
        """현재 사용자가 아닌 대화 상대 정보"""
        request = self.context.get('request')
        logger.debug(f"[ConversationListSerializer] Request in context: {request is not None}")
        logger.debug(f"[ConversationListSerializer] User authenticated: {request.user.is_authenticated if request else False}")

        if request and request.user.is_authenticated:
            other_user = obj.get_other_user(request.user)
            logger.debug(f"[ConversationListSerializer] Other user found: {other_user}")
            if other_user:
                return {
                    'id': other_user.id,
                    'nickname': other_user.nickname,
                    'profile_picture': other_user.profile_picture.url if other_user.profile_picture else None,
                }
        return None

    def get_last_message(self, obj):
        """마지막 메시지 내용 및 시간"""
        last_msg = obj.get_last_message()
        if last_msg:
            return {
                'content': last_msg.content,
                'created_at': last_msg.created_at,
                'sender_id': last_msg.sender.id,
            }
        return None

    def get_unread_count(self, obj):
        """읽지 않은 메시지 수"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.get_unread_count(request.user)
        return 0


class ConversationDetailSerializer(serializers.ModelSerializer):
    """Serializer for conversation details with message history"""
    messages = serializers.SerializerMethodField()
    other_user = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = ('id', 'other_user', 'messages', 'created_at', 'updated_at')
        read_only_fields = ('id', 'other_user', 'messages', 'created_at', 'updated_at')

    def get_messages(self, obj):
        """
        현재 사용자가 볼 수 있는 메시지만 반환
        - 나간 적이 있으면: left_at 이후의 메시지만
        - 나간 적이 없으면: 모든 메시지
        """
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return []

        # 현재 사용자의 참가자 정보 조회
        try:
            participant = ConversationParticipant.objects.get(
                conversation=obj,
                user=request.user
            )
        except ConversationParticipant.DoesNotExist:
            return []

        # 메시지 필터링
        messages = obj.messages.all()

        # 나간 적이 있으면 left_at 이후의 메시지만
        if participant.left_at:
            messages = messages.filter(created_at__gt=participant.left_at)

        # 만료되지 않은 메시지만 조회 (익명 채팅 7일 만료 정책)
        messages = messages.filter(is_expired=False)

        return MessageSerializer(messages, many=True).data

    def get_other_user(self, obj):
        """현재 사용자가 아닌 대화 상대 정보"""
        request = self.context.get('request')
        logger.debug(f"[ConversationDetailSerializer] Request in context: {request is not None}")
        logger.debug(f"[ConversationDetailSerializer] User authenticated: {request.user.is_authenticated if request else False}")

        if request and request.user.is_authenticated:
            other_user = obj.get_other_user(request.user)
            logger.debug(f"[ConversationDetailSerializer] Other user found: {other_user}")
            if other_user:
                return {
                    'id': other_user.id,
                    'nickname': other_user.nickname,
                    'profile_picture': other_user.profile_picture.url if other_user.profile_picture else None,
                }
        return None


class AnonymousMatchingPreferenceSerializer(serializers.ModelSerializer):
    """Serializer for anonymous matching preferences"""

    class Meta:
        model = AnonymousMatchingPreference
        fields = ('preferred_gender', 'preferred_country', 'chat_mode', 'is_searching', 'updated_at')
        read_only_fields = ('updated_at',)


class ReportSerializer(serializers.ModelSerializer):
    """Serializer for user reports"""
    reporter_nickname = serializers.CharField(source='reporter.nickname', read_only=True)
    reported_user_nickname = serializers.CharField(source='reported_user.nickname', read_only=True)

    class Meta:
        model = Report
        fields = ('id', 'reported_user', 'conversation', 'report_type', 'description',
                  'reporter_nickname', 'reported_user_nickname', 'status', 'created_at')
        read_only_fields = ('id', 'reporter_nickname', 'reported_user_nickname', 'status', 'created_at')

    def validate(self, data):
        """유효성 검사"""
        # 자기 자신을 신고하는 것 방지
        request = self.context.get('request')
        if request and data.get('reported_user') == request.user:
            raise serializers.ValidationError("자기 자신을 신고할 수 없습니다.")

        return data


class OpenChatMessageSerializer(serializers.ModelSerializer):
    """Serializer for open chat messages"""
    sender_id = serializers.IntegerField(source='sender.id', read_only=True)
    sender_nickname = serializers.CharField(source='sender.nickname', read_only=True)
    sender_profile_picture = serializers.CharField(source='sender.profile_picture', read_only=True)

    class Meta:
        model = OpenChatMessage
        fields = ('id', 'room', 'sender_id', 'sender_nickname', 'sender_profile_picture',
                  'content', 'created_at')
        read_only_fields = ('id', 'sender_id', 'sender_nickname', 'sender_profile_picture', 'created_at')


class OpenChatParticipantSerializer(serializers.ModelSerializer):
    """Serializer for open chat participants"""
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    user_username = serializers.CharField(source='user.username', read_only=True)
    user_nickname = serializers.CharField(source='user.nickname', read_only=True)
    user_profile_picture = serializers.CharField(source='user.profile_picture', read_only=True)

    class Meta:
        model = OpenChatParticipant
        fields = ('id', 'user', 'user_id', 'user_username', 'user_nickname', 'user_profile_picture',
                  'is_active', 'is_admin', 'admin_granted_at', 'joined_at', 'left_at')
        read_only_fields = ('id', 'user_id', 'user_username', 'user_nickname', 'user_profile_picture', 'admin_granted_at',
                            'joined_at', 'left_at')


class OpenChatRoomListSerializer(serializers.ModelSerializer):
    """Serializer for open chat room list"""
    participant_count = serializers.SerializerMethodField()
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    is_joined = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()
    is_admin = serializers.SerializerMethodField()
    creator_nickname = serializers.CharField(source='creator.nickname', read_only=True)
    last_message_time = serializers.SerializerMethodField()

    class Meta:
        model = OpenChatRoom
        fields = ('id', 'name', 'country_code', 'category', 'category_display',
                  'participant_count', 'max_participants', 'is_active',
                  'last_activity', 'last_message_time', 'created_at', 'is_joined', 'is_favorited',
                  'is_admin', 'creator_nickname')
        read_only_fields = ('id', 'participant_count', 'category_display', 'last_activity',
                            'last_message_time', 'created_at', 'is_joined', 'is_favorited', 'is_admin', 'creator_nickname')

    def get_participant_count(self, obj):
        """Return number of active participants"""
        return obj.get_participant_count()

    def get_is_joined(self, obj):
        """Check if current user is a participant"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.is_participant(request.user)
        return False

    def get_is_favorited(self, obj):
        """Check if current user has favorited this room"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return OpenChatFavorite.objects.filter(user=request.user, room=obj).exists()
        return False

    def get_is_admin(self, obj):
        """Check if current user is admin of this room"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.is_admin(request.user)
        return False

    def get_last_message_time(self, obj):
        """Get the timestamp of the last message in this room"""
        try:
            last_message = obj.open_messages.latest('created_at')
            return last_message.created_at
        except OpenChatMessage.DoesNotExist:
            return None


class OpenChatRoomDetailSerializer(serializers.ModelSerializer):
    """Serializer for open chat room details with messages"""
    messages = serializers.SerializerMethodField()
    participants = serializers.SerializerMethodField()
    participant_count = serializers.SerializerMethodField()
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    is_joined = serializers.SerializerMethodField()
    can_join = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()
    is_admin = serializers.SerializerMethodField()
    creator_nickname = serializers.CharField(source='creator.nickname', read_only=True)

    class Meta:
        model = OpenChatRoom
        fields = ('id', 'name', 'country_code', 'category', 'category_display',
                  'participant_count', 'max_participants', 'is_active',
                  'last_activity', 'created_at', 'messages', 'participants',
                  'is_joined', 'can_join', 'is_favorited', 'is_admin', 'creator_nickname')
        read_only_fields = ('id', 'participant_count', 'category_display', 'last_activity',
                            'created_at', 'messages', 'participants', 'is_joined', 'can_join',
                            'is_favorited', 'is_admin', 'creator_nickname')

    def get_messages(self, obj):
        """Return recent messages (last 50)"""
        messages = obj.open_messages.all().order_by('-created_at')[:50]
        # Reverse to show oldest first
        return OpenChatMessageSerializer(reversed(messages), many=True).data

    def get_participants(self, obj):
        """Return active participants"""
        active_participants = obj.participant_relations.filter(is_active=True)[:20]
        return OpenChatParticipantSerializer(active_participants, many=True).data

    def get_participant_count(self, obj):
        """Return number of active participants"""
        return obj.get_participant_count()

    def get_is_joined(self, obj):
        """Check if current user is a participant"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.is_participant(request.user)
        return False

    def get_can_join(self, obj):
        """Check if current user can join this room"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.can_join(request.user)
        return False

    def get_is_favorited(self, obj):
        """Check if current user has favorited this room"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return OpenChatFavorite.objects.filter(user=request.user, room=obj).exists()
        return False

    def get_is_admin(self, obj):
        """Check if current user is admin of this room"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.is_admin(request.user)
        return False


class OpenChatRoomCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating open chat rooms"""
    country_code = serializers.CharField(required=False, default='KR')

    class Meta:
        model = OpenChatRoom
        fields = ('name', 'country_code', 'category', 'max_participants', 'is_public', 'password')

    def validate_name(self, value):
        """Validate room name"""
        if len(value.strip()) < 2:
            raise serializers.ValidationError("채팅방 이름은 최소 2자 이상이어야 합니다.")
        return value.strip()

    def validate_max_participants(self, value):
        """Validate max participants"""
        if value < 2:
            raise serializers.ValidationError("최소 2명 이상이어야 합니다.")
        if value > 500:
            raise serializers.ValidationError("최대 500명까지 가능합니다.")
        return value

    def validate(self, data):
        """Validate password is provided for private rooms"""
        is_public = data.get('is_public', True)
        password = data.get('password', '')

        if not is_public and not password:
            raise serializers.ValidationError({
                'password': '비밀방은 비밀번호가 필요합니다.'
            })

        # Set default country_code if not provided
        if 'country_code' not in data or not data['country_code']:
            data['country_code'] = 'KR'

        return data

    def create(self, validated_data):
        """Create room and add creator as first participant"""
        request = self.context.get('request')

        # Set creator
        if request and request.user.is_authenticated:
            validated_data['creator'] = request.user

        room = OpenChatRoom.objects.create(**validated_data)

        # Add creator as first participant with admin privileges
        if request and request.user.is_authenticated:
            from django.utils import timezone
            OpenChatParticipant.objects.create(
                user=request.user,
                room=room,
                is_active=True,
                is_admin=True,
                admin_granted_at=timezone.now()
            )

        return room


class OpenChatFavoriteSerializer(serializers.ModelSerializer):
    """Serializer for favoriting/unfavoriting rooms"""
    room_name = serializers.CharField(source='room.name', read_only=True)
    room_category = serializers.CharField(source='room.get_category_display', read_only=True)

    class Meta:
        model = OpenChatFavorite
        fields = ('id', 'room', 'room_name', 'room_category', 'created_at')
        read_only_fields = ('id', 'room_name', 'room_category', 'created_at')

    def create(self, validated_data):
        """Create favorite, ensuring uniqueness"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            validated_data['user'] = request.user
        return super().create(validated_data)

    def validate(self, data):
        """Prevent duplicate favorites"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            if OpenChatFavorite.objects.filter(user=request.user, room=data['room']).exists():
                raise serializers.ValidationError("이미 즐겨찾기에 추가된 채팅방입니다.")
        return data


class OpenChatKickSerializer(serializers.ModelSerializer):
    """Serializer for kicking users from rooms"""
    kicked_user_nickname = serializers.CharField(source='kicked_user.nickname', read_only=True)
    kicked_by_nickname = serializers.CharField(source='kicked_by.nickname', read_only=True)
    room_name = serializers.CharField(source='room.name', read_only=True)
    is_ban_active = serializers.SerializerMethodField()

    class Meta:
        model = OpenChatKick
        fields = ('id', 'room', 'kicked_user', 'kicked_by', 'reason', 'kicked_at',
                  'ban_until', 'kicked_user_nickname', 'kicked_by_nickname', 'room_name',
                  'is_ban_active')
        read_only_fields = ('id', 'kicked_by', 'kicked_at', 'kicked_user_nickname',
                            'kicked_by_nickname', 'room_name', 'is_ban_active')

    def get_is_ban_active(self, obj):
        """Check if ban is still active"""
        return obj.is_ban_active()

    def create(self, validated_data):
        """Create kick record and set kicked_by"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            validated_data['kicked_by'] = request.user
        return super().create(validated_data)

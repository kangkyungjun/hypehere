from rest_framework import serializers
from accounts.serializers import UserSerializer
from .models import (
    ChatRoom,
    Message,
    BlockedUser,
    OpenChatRoom,
    OpenChatParticipant,
    OpenChatMessage,
)


class ChatRoomSerializer(serializers.ModelSerializer):
    """채팅방 Serializer"""

    user1 = UserSerializer(read_only=True)
    user2 = UserSerializer(read_only=True)
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    other_user = serializers.SerializerMethodField()

    class Meta:
        model = ChatRoom
        fields = [
            "id",
            "user1",
            "user2",
            "other_user",
            "country_code",
            "matching_score",
            "is_active",
            "user1_left",
            "user2_left",
            "last_message",
            "unread_count",
            "created_at",
            "updated_at",
        ]

    def get_last_message(self, obj):
        """마지막 메시지 반환"""
        last_msg = obj.messages.last()
        if last_msg:
            return {
                "content": last_msg.content,
                "sender": last_msg.sender.username,
                "created_at": last_msg.created_at,
            }
        return None

    def get_unread_count(self, obj):
        """읽지 않은 메시지 수"""
        request = self.context.get("request")
        if request and request.user:
            return obj.get_unread_count(request.user)
        return 0

    def get_other_user(self, obj):
        """상대방 사용자 정보"""
        request = self.context.get("request")
        if request and request.user:
            other = obj.get_other_user(request.user)
            if other:
                return UserSerializer(other).data
        return None


class MessageSerializer(serializers.ModelSerializer):
    """메시지 Serializer"""

    sender = UserSerializer(read_only=True)
    is_mine = serializers.SerializerMethodField()
    message_type = serializers.CharField(default='text', read_only=True)

    class Meta:
        model = Message
        fields = [
            "id",
            "room",
            "sender",
            "message_type",
            "content",
            "is_read",
            "is_mine",
            "created_at",
        ]
        read_only_fields = ["id", "sender", "is_read", "created_at"]

    def get_is_mine(self, obj):
        """내가 보낸 메시지인지 확인"""
        request = self.context.get("request")
        if request and request.user:
            return obj.sender == request.user
        return False


class MessageCreateSerializer(serializers.ModelSerializer):
    """메시지 생성 Serializer"""

    class Meta:
        model = Message
        fields = ["content"]

    def validate_content(self, value):
        """메시지 내용 검증"""
        if not value or len(value.strip()) == 0:
            raise serializers.ValidationError("메시지 내용을 입력해주세요.")

        if len(value) > 1000:
            raise serializers.ValidationError("메시지는 최대 1000자까지 입력 가능합니다.")

        return value


class MatchingRequestSerializer(serializers.Serializer):
    """매칭 요청 Serializer"""

    country_preference = serializers.CharField(
        max_length=3,
        required=False,
        allow_null=True,
        help_text="선호 국가 코드 (ISO 3166-1 alpha-3)"
    )


class BlockedUserSerializer(serializers.ModelSerializer):
    """차단 사용자 Serializer"""

    blocked_user = UserSerializer(read_only=True)

    class Meta:
        model = BlockedUser
        fields = [
            "id",
            "blocked_user",
            "reason",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class BlockUserSerializer(serializers.Serializer):
    """사용자 차단 Serializer"""

    user_id = serializers.IntegerField(required=True)
    reason = serializers.CharField(
        max_length=200,
        required=False,
        allow_blank=True
    )


# ============================================================================
# 오픈 채팅 Serializers
# ============================================================================


class OpenChatRoomSerializer(serializers.ModelSerializer):
    """오픈 채팅방 Serializer"""

    creator = UserSerializer(read_only=True)
    participants = serializers.SerializerMethodField()
    tags_list = serializers.SerializerMethodField()
    is_joined = serializers.SerializerMethodField()
    is_full = serializers.SerializerMethodField()
    can_delete = serializers.SerializerMethodField()

    class Meta:
        model = OpenChatRoom
        fields = [
            "id",
            "room_type",
            "title",
            "description",
            "country_code",
            "creator",
            "participants",
            "category",
            "tags",
            "tags_list",
            "participant_count",
            "max_participants",
            "is_full",
            "is_joined",
            "is_public",
            "can_delete",
            "is_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "room_type",
            "participant_count",
            "is_active",
            "created_at",
            "updated_at",
        ]

    def get_participants(self, obj):
        """참여자 목록 반환"""
        participants = OpenChatParticipant.objects.filter(room=obj).select_related("user")
        return [UserSerializer(p.user).data for p in participants]

    def get_tags_list(self, obj):
        """태그 리스트 반환"""
        return obj.get_tags_list()

    def get_is_joined(self, obj):
        """현재 사용자가 참여 중인지"""
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            return OpenChatParticipant.objects.filter(
                room=obj, user=request.user
            ).exists()
        return False

    def get_is_full(self, obj):
        """채팅방이 가득 찼는지"""
        return obj.is_full()

    def get_can_delete(self, obj):
        """현재 사용자가 채팅방을 삭제할 수 있는지"""
        from accounts.models import User

        request = self.context.get("request")
        if not request or not request.user.is_authenticated:
            return False

        user = request.user

        # prime, owner 역할은 모든 방 삭제 가능
        if user.role in [User.Role.PRIME, User.Role.OWNER]:
            return True

        # 본인이 생성한 USER_CREATED 방만 삭제 가능
        if obj.creator == user and obj.room_type == OpenChatRoom.RoomType.USER_CREATED:
            return True

        return False


class OpenChatRoomCreateSerializer(serializers.ModelSerializer):
    """오픈 채팅방 생성 Serializer"""

    class Meta:
        model = OpenChatRoom
        fields = [
            "title",
            "description",
            "country_code",
            "category",
            "tags",
            "max_participants",
            "is_public",
            "password",
        ]
        extra_kwargs = {
            "password": {"write_only": True}
        }

    def validate_title(self, value):
        """제목 검증"""
        if not value or len(value.strip()) < 2:
            raise serializers.ValidationError("제목은 최소 2자 이상이어야 합니다.")
        if len(value) > 100:
            raise serializers.ValidationError("제목은 최대 100자까지 입력 가능합니다.")
        return value

    def validate_max_participants(self, value):
        """최대 참여자 수 검증"""
        if value < 0:
            raise serializers.ValidationError("최대 참여자 수는 0 이상이어야 합니다.")
        if value > 1000:
            raise serializers.ValidationError("최대 참여자 수는 1000명을 초과할 수 없습니다.")
        return value

    def validate(self, attrs):
        """전체 데이터 검증"""
        # 사용자가 이미 생성한 채팅방이 있는지 확인
        request = self.context.get("request")
        if request and request.user:
            user = request.user

            # manager 이상의 사용자는 무한으로 채팅방 생성 가능
            if user.role in ['manager', 'prime', 'owner']:
                return attrs

            # 현재 생성한 활성 채팅방 수 확인
            existing_count = OpenChatRoom.objects.filter(
                creator=user,
                room_type=OpenChatRoom.RoomType.USER_CREATED,
                is_active=True,
            ).count()

            # premium 사용자는 3개까지 가능
            if user.role == 'premiumuser':
                if existing_count >= 3:
                    raise serializers.ValidationError(
                        "프리미엄 사용자는 최대 3개의 채팅방을 생성할 수 있습니다."
                    )
            # 일반 사용자는 1개만 가능
            else:
                if existing_count >= 1:
                    raise serializers.ValidationError(
                        "이미 생성한 채팅방이 있습니다. 일반 사용자는 1개의 채팅방만 생성할 수 있습니다."
                    )

        # 비공개 방 비밀번호 검증
        is_public = attrs.get('is_public', True)
        password = attrs.get('password', '')

        if not is_public:
            # 비공개 방인 경우 비밀번호 필수
            if not password or len(password.strip()) == 0:
                raise serializers.ValidationError({
                    "password": "비공개 채팅방은 비밀번호가 필요합니다."
                })
            # 비밀번호 최소 길이 검증
            if len(password) < 4:
                raise serializers.ValidationError({
                    "password": "비밀번호는 최소 4자 이상이어야 합니다."
                })

        return attrs


class OpenChatParticipantSerializer(serializers.ModelSerializer):
    """오픈 채팅방 참여자 Serializer"""

    user = UserSerializer(read_only=True)

    class Meta:
        model = OpenChatParticipant
        fields = [
            "id",
            "user",
            "joined_at",
            "last_read_at",
            "is_active",
        ]
        read_only_fields = ["id", "joined_at", "last_read_at"]


class OpenChatMessageSerializer(serializers.ModelSerializer):
    """오픈 채팅 메시지 Serializer"""

    sender = UserSerializer(read_only=True)
    is_mine = serializers.SerializerMethodField()

    class Meta:
        model = OpenChatMessage
        fields = [
            "id",
            "room",
            "sender",
            "message_type",
            "content",
            "is_mine",
            "created_at",
        ]
        read_only_fields = ["id", "sender", "message_type", "created_at"]

    def get_is_mine(self, obj):
        """내가 보낸 메시지인지"""
        request = self.context.get("request")
        if request and request.user and obj.sender:
            return obj.sender == request.user
        return False


class OpenChatMessageCreateSerializer(serializers.ModelSerializer):
    """오픈 채팅 메시지 생성 Serializer"""

    class Meta:
        model = OpenChatMessage
        fields = ["content"]

    def validate_content(self, value):
        """메시지 내용 검증"""
        if not value or len(value.strip()) == 0:
            raise serializers.ValidationError("메시지 내용을 입력해주세요.")

        if len(value) > 1000:
            raise serializers.ValidationError("메시지는 최대 1000자까지 입력 가능합니다.")

        return value

from django.contrib import admin
from .models import (
    MatchingQueue,
    ChatRoom,
    Message,
    BlockedUser,
    OpenChatRoom,
    OpenChatParticipant,
    OpenChatMessage,
)


@admin.register(MatchingQueue)
class MatchingQueueAdmin(admin.ModelAdmin):
    """매칭 대기열 관리"""

    list_display = ("user", "country_preference", "created_at")
    list_filter = ("country_preference", "created_at")
    search_fields = ("user__username",)
    ordering = ("created_at",)


@admin.register(ChatRoom)
class ChatRoomAdmin(admin.ModelAdmin):
    """채팅방 관리"""

    list_display = (
        "id",
        "user1",
        "user2",
        "country_code",
        "matching_score",
        "is_active",
        "user1_left",
        "user2_left",
        "created_at",
    )
    list_filter = ("is_active", "country_code", "created_at")
    search_fields = ("user1__username", "user2__username")
    raw_id_fields = ("user1", "user2")
    ordering = ("-created_at",)


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    """메시지 관리"""

    list_display = (
        "id",
        "room",
        "sender",
        "content_preview",
        "is_read",
        "created_at",
    )
    list_filter = ("is_read", "created_at")
    search_fields = ("sender__username", "content")
    raw_id_fields = ("room", "sender")
    ordering = ("-created_at",)

    def content_preview(self, obj):
        """메시지 내용 미리보기"""
        return obj.content[:50] + "..." if len(obj.content) > 50 else obj.content

    content_preview.short_description = "내용"


@admin.register(BlockedUser)
class BlockedUserAdmin(admin.ModelAdmin):
    """차단 사용자 관리"""

    list_display = ("user", "blocked_user", "reason", "created_at")
    list_filter = ("created_at",)
    search_fields = ("user__username", "blocked_user__username")
    raw_id_fields = ("user", "blocked_user")
    ordering = ("-created_at",)


@admin.register(OpenChatRoom)
class OpenChatRoomAdmin(admin.ModelAdmin):
    """오픈 채팅방 관리"""

    list_display = (
        "id",
        "title",
        "country_code",
        "room_type",
        "participant_count",
        "max_participants",
        "category",
        "creator",
        "is_active",
        "created_at",
    )
    list_filter = ("room_type", "country_code", "category", "is_active", "created_at")
    search_fields = ("title", "description", "tags")
    raw_id_fields = ("creator",)
    ordering = ("-participant_count", "-created_at")
    readonly_fields = ("participant_count", "created_at", "updated_at")

    fieldsets = (
        ("기본 정보", {
            "fields": ("room_type", "title", "description", "country_code")
        }),
        ("생성자", {
            "fields": ("creator",)
        }),
        ("카테고리/태그", {
            "fields": ("category", "tags")
        }),
        ("참여자", {
            "fields": ("participant_count", "max_participants")
        }),
        ("상태", {
            "fields": ("is_active",)
        }),
        ("타임스탬프", {
            "fields": ("created_at", "updated_at"),
            "classes": ("collapse",)
        }),
    )


@admin.register(OpenChatParticipant)
class OpenChatParticipantAdmin(admin.ModelAdmin):
    """오픈 채팅방 참여자 관리"""

    list_display = ("user", "room", "joined_at", "last_read_at", "is_active")
    list_filter = ("is_active", "joined_at")
    search_fields = ("user__username", "user__nickname", "room__title")
    raw_id_fields = ("room", "user")
    ordering = ("-joined_at",)


@admin.register(OpenChatMessage)
class OpenChatMessageAdmin(admin.ModelAdmin):
    """오픈 채팅 메시지 관리"""

    list_display = (
        "id",
        "room",
        "sender_nickname",
        "message_type",
        "content_preview",
        "created_at",
    )
    list_filter = ("message_type", "created_at")
    search_fields = ("sender__username", "sender__nickname", "content", "room__title")
    raw_id_fields = ("room", "sender")
    ordering = ("-created_at",)

    def sender_nickname(self, obj):
        """발신자 닉네임"""
        return obj.sender.nickname if obj.sender else "System"

    sender_nickname.short_description = "발신자"

    def content_preview(self, obj):
        """메시지 내용 미리보기"""
        return obj.content[:50] + "..." if len(obj.content) > 50 else obj.content

    content_preview.short_description = "내용"
